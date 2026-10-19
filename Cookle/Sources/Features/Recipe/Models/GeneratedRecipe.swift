import FoundationModels

/// Creative recipe fields, separate from the source-grounded extraction schema.
@available(iOS 26.0, *)
@Generable(description: "One practical recipe starting point to cook, adjust, and make your own.")
struct GeneratedRecipe {
    @Guide(description: "A concise dish name in the person's requested language.")
    var name: String
    @Guide(description: "Number of people served. Follow the request; otherwise choose a small household portion.")
    var servingSize: Int
    @Guide(description: "Estimated cooking time in minutes for this recipe.")
    var cookingTime: Int
    @Guide(description: "Ingredients and practical quantities for the stated servings.")
    var ingredients: [GeneratedRecipeIngredient]
    @Guide(description: "Ordered cooking instructions without step numbers or bullets. Include heat and doneness cues.")
    var steps: [String]
    @Guide(
        description: """
        Optional tips or substitutions. Empty when unnecessary. \
        No claims of verified safety or nutrition.
        """
    )
    var note: String

    var recipeInferenceResult: RecipeInferenceResult {
        .init(
            name: name,
            servingSize: servingSize,
            cookingTime: cookingTime,
            ingredients: ingredients.map { ingredient in
                .init(ingredient: ingredient.name, amount: ingredient.amount)
            },
            steps: steps,
            categories: [],
            note: note
        )
    }
}
