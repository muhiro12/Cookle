import FoundationModels

@Generable
struct GeneratedRecipe {
    @Guide(description: "Recipe title")
    var name: String

    @Guide(description: "List of ingredients")
    var ingredients: [String]

    @Guide(description: "Cooking steps")
    var steps: [String]
}
