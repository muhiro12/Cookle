import SwiftUI

@available(iOS 26.0, *)
struct GenerateRecipeFromPhotoButton: View {
    @Binding private var photos: [PhotoData]
    @Binding private var name: String
    @Binding private var servingSize: String
    @Binding private var cookingTime: String
    @Binding private var ingredients: [RecipeFormIngredient]
    @Binding private var steps: [String]
    @Binding private var note: String

    @State private var isProcessing = false

    init(photos: Binding<[PhotoData]>,
         name: Binding<String>,
         servingSize: Binding<String>,
         cookingTime: Binding<String>,
         ingredients: Binding<[RecipeFormIngredient]>,
         steps: Binding<[String]>,
         note: Binding<String>) {
        _photos = photos
        _name = name
        _servingSize = servingSize
        _cookingTime = cookingTime
        _ingredients = ingredients
        _steps = steps
        _note = note
    }

    var body: some View {
        Button {
            guard CookleFoundationModel.isSupported,
                  let data = photos.first?.data else { return }
            isProcessing = true
            Task {
                do {
                    let draft = try await OCRRecipeBuilder.build(from: data)
                    name = draft.name
                    servingSize = draft.servingSize
                    cookingTime = draft.cookingTime
                    ingredients = draft.ingredients + [(.empty, .empty)]
                    steps = draft.steps + [.empty]
                    note = draft.note
                } catch {
                    // ignore for now
                }
                isProcessing = false
            }
        } label: {
            if isProcessing {
                ProgressView()
            } else {
                Label {
                    Text("Generate From Photo")
                } icon: {
                    Image(systemName: "text.viewfinder")
                }
            }
        }
        .disabled(isProcessing || photos.isEmpty || !CookleFoundationModel.isSupported)
    }
}

@available(iOS 26.0, *)
#Preview {
    GenerateRecipeFromPhotoButton(
        photos: .constant([]),
        name: .constant(""),
        servingSize: .constant(""),
        cookingTime: .constant(""),
        ingredients: .constant([]),
        steps: .constant([]),
        note: .constant("")
    )
}
