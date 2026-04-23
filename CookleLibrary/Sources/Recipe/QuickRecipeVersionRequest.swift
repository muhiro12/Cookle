/// Input used to build a temporary quick view of an existing recipe.
public struct QuickRecipeVersionRequest: Equatable, Sendable {
    public let name: String
    public let cookingTime: Int
    public let ingredients: [String]
    public let steps: [String]

    public init(
        name: String,
        cookingTime: Int,
        ingredients: [String],
        steps: [String]
    ) {
        self.name = name
        self.cookingTime = cookingTime
        self.ingredients = ingredients
        self.steps = steps
    }
}
