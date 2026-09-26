import AppIntents
import CookleLibrary
import MHUI
import SwiftUI

@available(iOS 26.0, *)
struct InferRecipeFormView: View {
    private enum Layout {
        static let loadingOverlayOpacity = 0.2
    }

    /// An inference that finished after the form input changed, waiting for a
    /// new review before it may replace that input.
    private struct PendingInference {
        let inference: RecipeInferenceResult
        let sourceURL: URL?
    }

    private let model: RecipeFormModel
    private let source: RecipeImportSource
    private let initialPhotoData: Data?

    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.mhDesignMetrics)
    private var designMetrics

    @State private var hasOpenedSource = false
    @State private var text = ""
    @State private var sourceURL: URL?
    @State private var websiteSource: RecipeWebsiteSource?
    @State private var operationTask: Task<Void, Never>?
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var isReplacementReviewPresented = false
    @State private var pendingInference: PendingInference?
    @FocusState private var isTextFocused: Bool

    private let placeholder: LocalizedStringKey = .init(
        """
        Spaghetti Carbonara for 2 people.
        Ingredients: Spaghetti 200g, Eggs 2, Pancetta 100g.
        Cook spaghetti. Fry pancetta. Mix eggs and cheese. Combine all.
        """
    )

    var body: some View {
        TextEditor(text: $text)
            .focused($isTextFocused)
            .disabled(isLoading)
            .accessibilityLabel(Text("Recipe Text"))
            .accessibilityValue(Text(verbatim: text))
            .overlay(alignment: .topLeading) {
                placeholderOverlay
            }
            .scrollDismissesKeyboard(.immediately)
            .mhInputChrome(state: isTextFocused ? .focused : .normal)
            .padding()
            .navigationTitle(Text("Review Recipe Text"))
            .toolbar {
                toolbarItems
            }
            .font(nil)
            .overlay {
                loadingOverlay
            }
            .task {
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
                            errorMessage = CookleLibraryErrorCopy.description(for: error)
                        }
                    }
                } else if source == .text {
                    isTextFocused = true
                }
            }
            .onDisappear {
                operationTask?.cancel()
            }
            .alert(
                Text("Cannot Infer Recipe"),
                isPresented: isInferenceErrorPresented
            ) {
                Button("OK", role: .cancel) {
                    errorMessage = ""
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

    @ToolbarContentBuilder var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                operationTask?.cancel()
                dismiss()
            } label: {
                Text("Cancel")
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button {
                requestInference()
            } label: {
                Text("Create Draft")
            }
            .disabled(isLoading || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    @ViewBuilder var loadingOverlay: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(Layout.loadingOverlayOpacity).ignoresSafeArea()
                ProgressView()
            }
        }
    }

    init(
        model: RecipeFormModel,
        source: RecipeImportSource,
        initialWebsiteSource: RecipeWebsiteSource? = nil,
        initialSourceURL: URL? = nil,
        initialPhotoData: Data? = nil
    ) {
        self.initialPhotoData = initialPhotoData
        _text = State(initialValue: initialWebsiteSource?.text ?? "")
        _websiteSource = State(initialValue: initialWebsiteSource)
        _sourceURL = State(initialValue: initialSourceURL)
        self.model = model
        self.source = source
    }
}

@available(iOS 26.0, *)
private extension InferRecipeFormView {
    @ViewBuilder var placeholderOverlay: some View {
        if text.isEmpty {
            Text(placeholder)
                .font(.body)
                .foregroundStyle(.placeholder)
                .padding(
                    .vertical,
                    RecipeTextEditorLayout.placeholderVerticalPadding(
                        metrics: designMetrics
                    )
                )
                .padding(
                    .horizontal,
                    RecipeTextEditorLayout.placeholderHorizontalPadding
                )
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    var isInferenceErrorPresented: Binding<Bool> {
        .init(
            get: {
                !errorMessage.isEmpty
            },
            set: { isPresented in
                if isPresented == false {
                    errorMessage = ""
                }
            }
        )
    }

    @ViewBuilder var replacementReviewMessage: some View {
        if pendingInference != nil {
            Text(
                """
                The recipe input changed while importing. Review it again before the imported \
                recipe replaces it. You can undo the import from the recipe form.
                """
            )
        } else {
            Text(
                """
                The imported recipe replaces the name, servings, cooking time, ingredients, steps, \
                categories, and note you entered. Photos stay. You can undo the import from the \
                recipe form.
                """
            )
        }
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
            sourceURL: pendingInference.sourceURL
        )
        dismiss()
    }

    func startInference() {
        let reviewedInput = model.changeSnapshot
        isLoading = true
        operationTask = Task { @MainActor in
            await applyInference(
                reviewedInput: reviewedInput
            )
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
            var inference = try await RecipeFoundationModelInferenceOperations.infer(text: text)
            if let websiteSource, websiteSource.text == text {
                inference = websiteSource.grounding(inference)
            }
            try Task.checkCancellation()
            guard model.changeSnapshot == reviewedInput
                    || model.inferenceReplacesEnteredValues == false else {
                pendingInference = .init(
                    inference: inference,
                    sourceURL: sourceURL
                )
                isReplacementReviewPresented = true
                return
            }

            model.applyInference(
                inference,
                sourceURL: sourceURL
            )
            dismiss()
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
}
