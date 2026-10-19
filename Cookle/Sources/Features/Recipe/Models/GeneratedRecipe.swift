import FoundationModels

/// Creative recipe fields, separate from the source-grounded extraction schema.
@available(iOS 26.0, *)
@Generable(description: "One practical recipe starting point to cook, adjust, and make your own.")
struct GeneratedRecipe {
    @Guide(description: "A concise dish name in the person's requested language.")
    var name: String
    @Guide(
        description: "Number of people served. Follow the request; otherwise choose a small household portion.",
        .minimum(1)
    )
    var servingSize: Int
    @Guide(description: "Estimated cooking time in minutes. Use zero when no cooking is needed.", .minimum(0))
    var cookingTime: Int
    @Guide(
        description: "Ordered steps including preparation, heat, and doneness cues. No step numbers or bullets.",
        .count(1...Self.maximumStepCount)
    )
    var steps: [String]
    // Generate ingredients after the steps so the list can account for what they use.
    @Guide(
        description: "Separate ingredients and practical quantities for the stated servings.",
        .count(1...Self.maximumIngredientCount)
    )
    var ingredients: [GeneratedRecipeIngredient]
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

@available(iOS 26.0, *)
private extension GeneratedRecipe {
    static let maximumStepCount = 8
    static let maximumIngredientCount = 16
}
