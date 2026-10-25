import FoundationModels

@available(iOS 26.0, *)
@Generable(description: "One ingredient in the creative recipe.")
struct GeneratedRecipeIngredient {
    @Guide(description: "One common ingredient name in the requested language. No quantities or preparation details.")
    var name: String
    @Guide(
        description: """
        Total quantity and unit for all stated servings. Preserve requested quantities. For added pantry \
        ingredients, use familiar kitchen measures, simple spoon fractions or a pinch for tiny amounts. \
        Avoid unnecessary decimal spoon precision. Preparation belongs in the cooking steps.
        """
    )
    var amount: String
}
