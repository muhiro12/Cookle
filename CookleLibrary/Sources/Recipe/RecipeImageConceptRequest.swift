/// Input used to build Image Playground concepts from recipe content.
public struct RecipeImageConceptRequest: Sendable {
    public let name: String
    public let ingredients: [String]
    public let steps: [String]

    public init(
        name: String,
        ingredients: [String],
        steps: [String]
    ) {
        self.name = name
        self.ingredients = ingredients
        self.steps = steps
    }
}
