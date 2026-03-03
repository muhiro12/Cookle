import Foundation

@available(iOS 26.0, *)
struct RecipeFormGeneratedRecipe {
    let name: String
    let servingSize: String
    let cookingTime: String
    let ingredients: [RecipeFormIngredient]
    let steps: [String]
    let categories: [String]
    let note: String

    init(inference: InferredRecipe) {
        self.name = inference.name
        self.servingSize = inference.servingSize == 0 ? "" : inference.servingSize.description
        self.cookingTime = inference.cookingTime == 0 ? "" : inference.cookingTime.description
        self.ingredients = inference.ingredients.map { inferredIngredient in
            .init(
                ingredient: inferredIngredient.ingredient,
                amount: inferredIngredient.amount
            )
        } + [.init(ingredient: .empty, amount: .empty)]
        self.steps = inference.steps + [.empty]
        self.categories = inference.categories + [.empty]
        self.note = inference.note
    }
}
