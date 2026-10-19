import FoundationModels

@available(iOS 26.0, *)
@Generable(description: "One ingredient in the creative recipe.")
struct GeneratedRecipeIngredient {
    @Guide(description: "One common ingredient name in the requested language. No quantities or preparation details.")
    var name: String
    @Guide(description: "A realistic quantity and unit for this ingredient. Preparation belongs in the cooking steps.")
    var amount: String
}
