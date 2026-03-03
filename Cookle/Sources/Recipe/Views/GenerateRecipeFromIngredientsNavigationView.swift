import SwiftUI

@available(iOS 26.0, *)
struct GenerateRecipeFromIngredientsNavigationView: View {
    @Binding var name: String
    @Binding var servingSize: String
    @Binding var cookingTime: String
    @Binding var ingredients: [RecipeFormIngredient]
    @Binding var steps: [String]
    @Binding var categories: [String]
    @Binding var note: String

    var body: some View {
        NavigationStack {
            GenerateRecipeFromIngredientsView(
                name: $name,
                servingSize: $servingSize,
                cookingTime: $cookingTime,
                ingredients: $ingredients,
                steps: $steps,
                categories: $categories,
                note: $note
            )
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
