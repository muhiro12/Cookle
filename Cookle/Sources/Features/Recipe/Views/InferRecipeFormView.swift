import AppIntents
import CookleLibrary
import MHUI
import PhotosUI
import SwiftUI
import UIKit

@available(iOS 26.0, *)
struct InferRecipeFormView: View {
    private enum RecipeTextImporter {
        static func recognize(in data: Data) async throws -> String {
            try await Task.detached(priority: .userInitiated) {
                guard let image = UIImage(data: data) else {
                    throw RecipeTextImportError.imageDecodingFailed
                }

                let recognizedText: String
                do {
                    recognizedText = try TextRecognitionService.recognize(in: image)
                } catch {
                    throw RecipeTextImportError.textRecognitionFailed
                }

                let trimmedText = recognizedText.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                guard trimmedText.isEmpty == false else {
                    throw RecipeTextImportError.noRecognizedText
                }
                return trimmedText
            }.value
        }
    }

    private enum RecipeTextImportError: LocalizedError, Sendable {
        case photoDataUnavailable
        case imageDecodingFailed
        case textRecognitionFailed
        case noRecognizedText

        var errorDescription: String? {
            switch self {
            case .photoDataUnavailable:
                String(
                    localized: "The selected photo could not be loaded. Choose another photo and try again.",
                    comment: "Error shown when the recipe text importer cannot load a photo library selection."
                )
            case .imageDecodingFailed:
                String(
                    localized: "The photo could not be read. Choose another photo and try again.",
                    comment: "Error shown when the recipe text importer cannot decode the selected or captured image."
                )
            case .textRecognitionFailed:
                String(
                    localized: "Text recognition failed. Try again with a clearer photo.",
                    comment: "Error shown when Vision fails to recognize recipe text in a photo."
                )
            case .noRecognizedText:
                String(
                    localized: "No text was found in the photo. Try again with a photo that contains clear text.",
                    comment: "Error shown when text recognition succeeds but finds no recipe text in a photo."
                )
            }
        }
    }

    private enum Layout {
        static let loadingOverlayOpacity = 0.2
    }

    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.mhDesignMetrics)
    private var designMetrics

    @Binding private var name: String
    @Binding private var servingSize: String
    @Binding private var cookingTime: String
    @Binding private var ingredients: [RecipeFormIngredient]
    @Binding private var steps: [String]
    @Binding private var categories: [String]
    @Binding private var note: String

    @State private var text = ""
    @State private var sourceURL: URL?
    @State private var websiteSource: RecipeWebsiteSource?
    @State private var isWebsiteImporterPresented = false
    @State private var pendingWebsiteText: RecipeWebsiteSource?
    @State private var pendingWebsiteURL: URL?
    @State private var operationTask: Task<Void, Never>?
    @State private var isLoading = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isPhotoPickerPresented = false
    @State private var isCameraPickerPresented = false
    @State private var errorMessage = ""
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
            .scrollContentBackground(.hidden)
            .mhInputChrome(state: isTextFocused ? .focused : .normal)
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("Recipe Text"))
            .toolbar {
                toolbarItems
            }
            .font(nil)
            .overlay {
                loadingOverlay
            }
            .photosPicker(isPresented: $isPhotoPickerPresented, selection: $photoPickerItem, matching: .images)
            .fullScreenCover(isPresented: $isCameraPickerPresented) {
                CameraPicker { data in
                    handleCapturedPhoto(data)
                }
            }
            .sheet(isPresented: $isWebsiteImporterPresented) {
                RecipeWebsiteImportView { importedText, url in
                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        text = importedText.text
                        websiteSource = importedText
                        sourceURL = url
                    } else {
                        pendingWebsiteText = importedText
                        pendingWebsiteURL = url
                    }
                }
            }
            .confirmationDialog("Replace Recipe Text?", isPresented: .init(
                get: { pendingWebsiteText != nil && !isWebsiteImporterPresented },
                set: { isPresented in
                    if !isPresented {
                        pendingWebsiteText = nil
                        pendingWebsiteURL = nil
                    }
                }
            )) {
                Button("Replace", role: .destructive) {
                    text = pendingWebsiteText?.text ?? text
                    websiteSource = pendingWebsiteText
                    sourceURL = pendingWebsiteURL
                    pendingWebsiteText = nil
                    pendingWebsiteURL = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingWebsiteText = nil
                    pendingWebsiteURL = nil
                }
            } message: {
                Text("Replace the current text with the recipe from this page?")
            }
            .onDisappear {
                operationTask?.cancel()
            }
            .onChange(of: photoPickerItem) {
                handlePhotoPickerChange()
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
                isLoading = true
                operationTask = Task { @MainActor in
                    await applyInference()
                }
            } label: {
                Text("Done")
            }
            .disabled(isLoading || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        ToolbarItem(placement: .bottomBar) {
            importTextMenu
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

    var importTextMenu: some View {
        Menu {
            Button {
                isWebsiteImporterPresented = true
            } label: {
                Label("Import from Website", systemImage: "link")
            }
            if RecipePhotoInputSource.camera.isAvailable {
                Button {
                    isCameraPickerPresented = true
                } label: {
                    RecipePhotoInputSource.camera.label
                }
            }
            Button {
                isPhotoPickerPresented = true
            } label: {
                RecipePhotoInputSource.photoLibrary.label
            }
        } label: {
            Image(systemName: "text.viewfinder")
                .accessibilityLabel(Text("Import Text"))
        }
        .disabled(isLoading)
    }

    init(
        name: Binding<String>,
        servingSize: Binding<String>,
        cookingTime: Binding<String>,
        ingredients: Binding<[RecipeFormIngredient]>,
        steps: Binding<[String]>,
        categories: Binding<[String]>,
        note: Binding<String>
    ) {
        self._name = name
        self._servingSize = servingSize
        self._cookingTime = cookingTime
        self._ingredients = ingredients
        self._steps = steps
        self._categories = categories
        self._note = note
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

    @MainActor
    func applyInference() async {
        defer {
            isLoading = false
        }

        do {
            var inference = try await RecipeFoundationModelInferenceOperations.infer(text: text)
            if let websiteSource, websiteSource.text == text {
                inference = websiteSource.grounding(inference)
            }
            try Task.checkCancellation()
            name = inference.name
            servingSize = inference.servingSize == .zero ? "" : inference.servingSize.description
            cookingTime = inference.cookingTime == .zero ? "" : inference.cookingTime.description
            ingredients = inference.ingredients.map { inferredIngredient in
                .init(
                    ingredient: inferredIngredient.ingredient,
                    amount: inferredIngredient.amount
                )
            } + [.init(ingredient: "", amount: "")]
            steps = inference.steps + [""]
            categories = inference.categories + [""]
            note = RecipeWebsiteImportOperations.note(inference.note, sourceURL: sourceURL)
            dismiss()
        } catch {
            guard !Task.isCancelled else {
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    func handlePhotoPickerChange() {
        guard let photoPickerItem else {
            return
        }
        self.photoPickerItem = nil
        guard !isLoading else {
            return
        }
        isLoading = true
        operationTask = Task { @MainActor in
            defer {
                isLoading = false
            }

            do {
                guard let data = try await photoPickerItem.loadTransferable(
                    type: Data.self
                ) else {
                    throw RecipeTextImportError.photoDataUnavailable
                }
                try await appendRecognizedText(from: data)
            } catch let error as RecipeTextImportError {
                guard !Task.isCancelled else {
                    return
                }
                errorMessage = error.localizedDescription
            } catch {
                guard !Task.isCancelled else {
                    return
                }
                errorMessage = RecipeTextImportError.photoDataUnavailable.localizedDescription
            }
        }
    }

    func handleCapturedPhoto(_ data: Data) {
        guard !isLoading else {
            return
        }
        isLoading = true
        operationTask = Task { @MainActor in
            defer {
                isLoading = false
            }

            do {
                try await appendRecognizedText(from: data)
            } catch let error as RecipeTextImportError {
                guard !Task.isCancelled else {
                    return
                }
                errorMessage = error.localizedDescription
            } catch {
                guard !Task.isCancelled else {
                    return
                }
                errorMessage = RecipeTextImportError.textRecognitionFailed.localizedDescription
            }
        }
    }

    func appendRecognizedText(from data: Data) async throws {
        let recognizedText = try await RecipeTextImporter.recognize(in: data)
        try Task.checkCancellation()
        text += (text.isEmpty ? "" : "\n") + recognizedText
    }
}
