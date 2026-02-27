import AppIntents
import PhotosUI
import SwiftUI

@available(iOS 26.0, *)
struct InferRecipeFormView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding private var name: String
    @Binding private var servingSize: String
    @Binding private var cookingTime: String
    @Binding private var ingredients: [RecipeFormIngredient]
    @Binding private var steps: [String]
    @Binding private var categories: [String]
    @Binding private var note: String

    @State private var text = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var cameraPickerItem: PhotosPickerItem?
    @State private var isPhotoPickerPresented = false
    @State private var isCameraPickerPresented = false

    private let placeholder: LocalizedStringKey = """
        Spaghetti Carbonara for 2 people.
        Ingredients: Spaghetti 200g, Eggs 2, Pancetta 100g.
        Cook spaghetti. Fry pancetta. Mix eggs and cheese. Combine all.
        """

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

    var body: some View {
        TextEditor(text: $text)
            .overlay(alignment: .topLeading) {
                Text(placeholder)
                    .font(.body)
                    .foregroundStyle(.placeholder)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 6)
                    .allowsHitTesting(false)
                    .hidden(text.isNotEmpty)
            }
            .padding()
            .scrollContentBackground(.hidden)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 8))
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("Recipe Text"))
            .toolbar {
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
                            defer { isLoading = false }
                            do {
                                let inference = try await RecipeService.infer(text: text)
                                name = inference.name
                                servingSize = inference.servingSize == 0 ? "" : inference.servingSize.description
                                cookingTime = inference.cookingTime == 0 ? "" : inference.cookingTime.description
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
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        Text("Done")
                    }
                    .disabled(isLoading)
                }
                ToolbarItem(placement: .bottomBar) {
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
                    }
                }
            }
            .font(nil)
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView()
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
                Button("OK") { errorMessage = nil }
            }, message: {
                Text(errorMessage ?? "")
            })
            .photosPicker(isPresented: $isPhotoPickerPresented, selection: $photoPickerItem, matching: .images)
            .photosPicker(isPresented: $isCameraPickerPresented, selection: $cameraPickerItem, matching: .images)
            .onChange(of: photoPickerItem) {
                guard let photoPickerItem else {
                    return
                }
                Task {
                    if let data = try? await photoPickerItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data),
                       let recognized = try? TextRecognitionService.recognize(in: image) {
                        text += (text.isEmpty ? "" : "\n") + recognized
                    }
                    self.photoPickerItem = nil
                }
            }
            .onChange(of: cameraPickerItem) {
                guard let cameraPickerItem else {
                    return
                }
                Task {
                    if let data = try? await cameraPickerItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data),
                       let recognized = try? TextRecognitionService.recognize(in: image) {
                        text += (text.isEmpty ? "" : "\n") + recognized
                    }
                    self.cameraPickerItem = nil
                }
            }
    }
}
