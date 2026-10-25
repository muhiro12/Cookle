import AppIntents
import CookleLibrary
import MHPlatform
import MHUI
import SwiftUI

@available(iOS 26.0, *)
struct InferRecipeFormView: View {
    /// An inference that finished after the form input changed, waiting for a
    /// new review before it may replace that input.
    private struct PendingInference {
        let inference: RecipeInferenceResult
        let sourceURL: URL?
        let generationStatus: RecipeGenerationStatus?
    }

    private let model: RecipeFormModel
    private let source: RecipeDraftSource
    private let generationInputStyle: RecipeGenerationInputStyle
    private let generationRequest: Binding<String>?
    private let generationLoading: Binding<Bool>?
    private let hasPendingGenerationRequest: Bool
    private let initialPhotoData: Data?
    private let choosesAnotherPhoto: (() -> Void)?
    private let onInferenceApplied: (() -> Void)?

    @Environment(\.dismiss)
    private var dismiss

    @State private var hasOpenedSource = false
    @State private var localText = ""
    @State private var sourceURL: URL?
    @State private var websiteSource: RecipeWebsiteSource?
    @State private var operationTask: Task<Void, Never>?
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var isPhotoRecognitionFailure = false
    @State private var isReplacementReviewPresented = false
    @State private var pendingInference: PendingInference?
    @State private var generationStatus: RecipeGenerationStatus?

    var body: some View {
        Group {
            if source == .generation {
                RecipeGenerationInputView(
                    style: generationInputStyle,
                    text: textBinding,
                    isLoading: isLoading,
                    requestsFocus: onInferenceApplied == nil
                )
            } else {
                RecipeRequestEditorView(
                    text: textBinding,
                    source: source,
                    isLoading: isLoading,
                    requestsFocus: source == .text
                )
                .padding()
            }
        }
        .navigationTitle(source == .generation ? Text("Create with AI") : Text("Review Recipe Text"))
        .toolbar {
            toolbarItems
        }
        .font(nil)
        .overlay {
            if isLoading {
                RecipeGenerationProgressView(status: source == .generation ? generationStatus : nil)
            }
        }
        .task {
            await openSourceIfNeeded()
        }
        .onDisappear {
            operationTask?.cancel()
            generationLoading?.wrappedValue = false
        }
        .onChange(of: isLoading) {
            generationLoading?.wrappedValue = isLoading
        }
        .alert(
            isPhotoRecognitionFailure ? Text("Cannot Read Photo") : errorTitle,
            isPresented: isInferenceErrorPresented
        ) {
            if isPhotoRecognitionFailure, let choosesAnotherPhoto {
                Button("Choose Another Photo") {
                    clearError()
                    choosesAnotherPhoto()
                }
            }
            Button("OK", role: .cancel) {
                clearError()
            }
        } message: {
            Text(errorMessage)
        }
        .confirmationDialog(
            Text("Replace Current Input?"),
            isPresented: $isReplacementReviewPresented,
            titleVisibility: .visible
        ) {
            Button("Replace", role: .destructive) {
                confirmReplacement()
            }
            Button("Cancel", role: .cancel) {
                pendingInference = nil
            }
        } message: {
            replacementReviewMessage
        }
    }

    private var textBinding: Binding<String> {
        generationRequest ?? $localText
    }

    private var text: String {
        get { textBinding.wrappedValue }
        nonmutating set { textBinding.wrappedValue = newValue }
    }

    private var canSubmit: Bool {
        !isLoading
            && !hasPendingGenerationRequest
            && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (source != .generation || RecipeModelGenerationOperations.canGenerate)
    }

    @ToolbarContentBuilder var toolbarItems: some ToolbarContent {
        if onInferenceApplied == nil || isLoading {
            ToolbarItem(placement: .cancellationAction) {
                CancelButton {
                    operationTask?.cancel()
                    if onInferenceApplied == nil {
                        dismiss()
                    }
                }
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button(action: requestInference) {
                Label {
                    if source == .generation {
                        Text("Create with PCC")
                    } else {
                        Text("Create Draft")
                    }
                } icon: {
                    Image(systemName: "sparkles")
                }
            }
            .disabled(!canSubmit)
        }
    }

    /// - Parameter choosesAnotherPhoto: Returns to photo selection after the
    ///   initial photo yields no readable text. Pass `nil` when the view was
    ///   not opened from a photo.
    init(
        model: RecipeFormModel,
        source: RecipeDraftSource,
        generationInputStyle: RecipeGenerationInputStyle = .editor,
        generationRequest: Binding<String>? = nil,
        generationLoading: Binding<Bool>? = nil,
        hasPendingGenerationRequest: Bool = false,
        initialWebsiteSource: RecipeWebsiteSource? = nil,
        initialSourceURL: URL? = nil,
        initialPhotoData: Data? = nil,
        choosesAnotherPhoto: (() -> Void)? = nil,
        onInferenceApplied: (() -> Void)? = nil
    ) {
        self.initialPhotoData = initialPhotoData
        self.choosesAnotherPhoto = choosesAnotherPhoto
        self.onInferenceApplied = onInferenceApplied
        _localText = State(initialValue: initialWebsiteSource?.text ?? "")
        _websiteSource = State(initialValue: initialWebsiteSource)
        _sourceURL = State(initialValue: initialSourceURL)
        self.model = model
        self.source = source
        self.generationInputStyle = generationInputStyle
        self.generationRequest = generationRequest
        self.generationLoading = generationLoading
        self.hasPendingGenerationRequest = hasPendingGenerationRequest
    }
}

@available(iOS 26.0, *)
private extension InferRecipeFormView {
    var errorTitle: Text {
        source == .generation ? Text("Cannot Create Recipe") : Text("Cannot Infer Recipe")
    }

    var isInferenceErrorPresented: Binding<Bool> {
        .init(
            get: {
                !errorMessage.isEmpty
            },
            set: { isPresented in
                if isPresented == false {
                    clearError()
                }
            }
        )
    }

    @ViewBuilder var replacementReviewMessage: some View {
        if pendingInference != nil {
            Text(
                """
                The recipe input changed while preparing the draft. Review it again before the \
                draft replaces it. You can undo this from the recipe form.
                """
            )
        } else {
            Text(
                """
                The recipe draft replaces the name, servings, cooking time, ingredients, steps, \
                categories, and note you entered. Photos stay. You can undo this from the recipe form.
                """
            )
        }
    }

    func openSourceIfNeeded() async {
        guard !hasOpenedSource else {
            return
        }
        hasOpenedSource = true
        if let initialPhotoData {
            isLoading = true
            defer {
                isLoading = false
            }
            do {
                try await appendRecognizedText(from: initialPhotoData)
            } catch {
                if !Task.isCancelled {
                    isPhotoRecognitionFailure = true
                    errorMessage = CookleLibraryErrorCopy.description(for: error)
                }
            }
        }
    }

    func clearError() {
        errorMessage = ""
        isPhotoRecognitionFailure = false
    }

    /// Asks before an inference may replace entered values; a blank form needs no review.
    func requestInference() {
        guard model.inferenceReplacesEnteredValues else {
            startInference()
            return
        }

        pendingInference = nil
        isReplacementReviewPresented = true
    }

    func confirmReplacement() {
        guard let pendingInference else {
            startInference()
            return
        }

        // The input was reviewed again just now, so the finished inference can apply.
        self.pendingInference = nil
        model.applyInference(
            pendingInference.inference,
            sourceURL: pendingInference.sourceURL,
            generationStatus: pendingInference.generationStatus
        )
        finishInference()
    }

    func startInference() {
        guard !isLoading else {
            return
        }
        model.captureInitialChangeSnapshotIfNeeded()
        let reviewedInput = model.changeSnapshot
        generationStatus = nil
        isLoading = true
        operationTask = Task { @MainActor in
            await applyInference(reviewedInput: reviewedInput)
        }
    }

    /// Applies the inference only against the input that was reviewed.
    ///
    /// If the form changed while the model was working, the earlier review no
    /// longer covers it; the result waits for a new review instead.
    @MainActor
    func applyInference(
        reviewedInput: RecipeFormChangeSnapshot
    ) async {
        defer {
            isLoading = false
        }

        do {
            var inference: RecipeInferenceResult
            if source == .generation {
                inference = try await RecipeModelGenerationOperations.generate(
                    request: text
                ) { status in
                    guard !Task.isCancelled else {
                        return
                    }
                    generationStatus = status
                }
            } else {
                inference = try await RecipeFoundationModelInferenceOperations.infer(text: text)
            }
            if let websiteSource, websiteSource.text == text {
                inference = websiteSource.grounding(inference)
            }
            try Task.checkCancellation()
            guard model.changeSnapshot == reviewedInput
                    || model.inferenceReplacesEnteredValues == false else {
                pendingInference = .init(
                    inference: inference,
                    sourceURL: sourceURL,
                    generationStatus: generationStatus
                )
                isReplacementReviewPresented = true
                return
            }

            model.applyInference(
                inference,
                sourceURL: sourceURL,
                generationStatus: generationStatus
            )
            finishInference()
        } catch {
            guard !Task.isCancelled, !(error is CancellationError) else {
                return
            }
            errorMessage = CookleLibraryErrorCopy.description(for: error)
        }
    }

    func appendRecognizedText(from data: Data) async throws {
        let recognizedText = try await RecipeTextImporter.recognize(in: data)
        try Task.checkCancellation()
        text += (text.isEmpty ? "" : "\n") + recognizedText
    }

    func finishInference() {
        if let onInferenceApplied {
            onInferenceApplied()
        } else {
            dismiss()
        }
    }
}

#Preview("Create with AI") {
    if #available(iOS 26.0, *) {
        NavigationStack {
            InferRecipeFormView(model: .init(type: .create), source: .generation)
        }
    }
}
