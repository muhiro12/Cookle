import SwiftUI

@available(iOS 26.0, *)
struct RecipeFormInferSection: View {
    @Binding private var name: String
    @Binding private var servingSize: String
    @Binding private var cookingTime: String
    @Binding private var ingredients: [RecipeFormIngredient]
    @Binding private var steps: [String]
    @Binding private var categories: [String]
    @Binding private var note: String

    init(name: Binding<String>,
         servingSize: Binding<String>,
         cookingTime: Binding<String>,
         ingredients: Binding<[RecipeFormIngredient]>,
         steps: Binding<[String]>,
         categories: Binding<[String]>,
         note: Binding<String>) {
        _name = name
        _servingSize = servingSize
        _cookingTime = cookingTime
        _ingredients = ingredients
        _steps = steps
        _categories = categories
        _note = note
    }

    var body: some View {
        Section {
            InferRecipeFormButton(
                name: $name,
                servingSize: $servingSize,
                cookingTime: $cookingTime,
                ingredients: $ingredients,
                steps: $steps,
                categories: $categories,
                note: $note
            )
            .frame(maxWidth: .infinity)
        } header: {
            Text("Infer From Text")
        }
    }
}
