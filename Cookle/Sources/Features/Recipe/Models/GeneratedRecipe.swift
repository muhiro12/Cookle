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
    @Guide(
        description: """
        Estimated total preparation, waiting and cooking time in minutes, \
        including preparation for uncooked dishes.
        """,
        .minimum(0)
    )
    var cookingTime: Int
    @Guide(
        description: """
        Complete ordered steps in the requested language. Start with necessary preparation, \
        such as cutting sizes and draining, then cooking with heat, timing, and doneness cues. \
        Include everything needed to make the dish here. No step numbers or bullets.
        """,
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
        Optional tips or substitutions in the requested language. Empty when unnecessary. \
        Essential preparation and cooking belong in the steps, never only here. \
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
