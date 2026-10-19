import FoundationModels

@available(iOS 26.0, *)
@Generable(description: "One ingredient in the creative recipe.")
struct GeneratedRecipeIngredient {
    @Guide(description: "Reusable base ingredient name in the requested language.")
    var name: String
    @Guide(description: "Quantity with unit; include any preparation detail such as sliced here.")
    var amount: String
}
