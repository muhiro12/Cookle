import AppIntents
import PhotosUI
import SwiftUI

@available(iOS 26.0, *)
struct InferRecipeFormView: View {
    private enum Layout {
        static let placeholderVerticalPadding = CGFloat(Int("8") ?? .zero)
        static let placeholderHorizontalPadding = CGFloat(Int("6") ?? .zero)
        static let textEditorCornerRadius = CGFloat(Int("8") ?? .zero)
        static let loadingOverlayOpacity = Double("0.2") ?? .zero
    }

    @Environment(\.dismiss)
    private var dismiss

    @Binding private var name: String
    @Binding private var servingSize: String
    @Binding private var cookingTime: String
    @Binding private var ingredients: [RecipeFormIngredient]
    @Binding private var steps: [String]
    @Binding private var categories: [String]
    @Binding private var note: String

    @State private var text = ""
    @State private var isLoading = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var cameraPickerItem: PhotosPickerItem?
    @State private var isPhotoPickerPresented = false
    @State private var isCameraPickerPresented = false

    private let placeholder: LocalizedStringKey = """
        Spaghetti Carbonara for 2 people.
        Ingredients: Spaghetti 200g, Eggs 2, Pancetta 100g.
        Cook spaghetti. Fry pancetta. Mix eggs and cheese. Combine all.
        """

    var body: some View {
        TextEditor(text: $text)
            .overlay(alignment: .topLeading) {
                placeholderOverlay
            }
            .padding()
            .scrollContentBackground(.hidden)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: Layout.textEditorCornerRadius))
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
            .photosPicker(isPresented: $isCameraPickerPresented, selection: $cameraPickerItem, matching: .images)
            .onChange(of: photoPickerItem) {
                handlePhotoPickerChange()
            }
            .onChange(of: cameraPickerItem) {
                handleCameraPickerChange()
            }
    }

    var placeholderOverlay: some View {
        Text(placeholder)
            .font(.body)
            .foregroundStyle(.placeholder)
            .padding(.vertical, Layout.placeholderVerticalPadding)
            .padding(.horizontal, Layout.placeholderHorizontalPadding)
            .allowsHitTesting(false)
            .hidden(text.isNotEmpty)
    }

    @ToolbarContentBuilder var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                text = ""
                dismiss()
            } label: {
                Text("Cancel")
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button {
                isLoading = true
                Task {
                    await applyInference()
                }
            } label: {
                Text("Done")
            }
            .disabled(isLoading)
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
                isCameraPickerPresented = true
            } label: {
                Label("Camera", systemImage: "camera")
            }
            Button {
                isPhotoPickerPresented = true
            } label: {
                Label("Photo Library", systemImage: "photo")
            }
        } label: {
            Image(systemName: "text.viewfinder")
                .accessibilityLabel(Text("Import Text"))
        }
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
    @MainActor
    func applyInference() async {
        defer {
            isLoading = false
        }

        let inference = await RecipeService.infer(text: text)
        name = inference.name
        servingSize = inference.servingSize == .zero ? .empty : inference.servingSize.description
        cookingTime = inference.cookingTime == .zero ? .empty : inference.cookingTime.description
        ingredients = inference.ingredients.map { inferredIngredient in
            .init(
                ingredient: inferredIngredient.ingredient,
                amount: inferredIngredient.amount
            )
        } + [.init(ingredient: .empty, amount: .empty)]
        steps = inference.steps + [.empty]
        categories = inference.categories + [.empty]
        note = inference.note
        dismiss()
    }

    func handlePhotoPickerChange() {
        guard let photoPickerItem else {
            return
        }
        Task {
            await appendRecognizedText(from: photoPickerItem)
            self.photoPickerItem = nil
        }
    }

    func handleCameraPickerChange() {
        guard let cameraPickerItem else {
            return
        }
        Task {
            await appendRecognizedText(from: cameraPickerItem)
            self.cameraPickerItem = nil
        }
    }

    func appendRecognizedText(from pickerItem: PhotosPickerItem) async {
        guard let data = try? await pickerItem.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let recognized = try? TextRecognitionService.recognize(in: image) else {
            return
        }
        text += (text.isEmpty ? "" : "\n") + recognized
    }
}
