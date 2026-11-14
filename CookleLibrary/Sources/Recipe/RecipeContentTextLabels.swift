/// Localized headings supplied by the presentation surface for readable recipe text.
public struct RecipeContentTextLabels: Sendable {
    public let servings: String
    public let cookingTime: String
    public let ingredients: String
    public let steps: String
    public let categories: String
    public let note: String

    /// Creates headings. The cooking-time heading must identify minutes as its unit.
    public init(
        servings: String,
        cookingTime: String,
        ingredients: String,
        steps: String,
        categories: String,
        note: String
    ) {
        self.servings = servings
        self.cookingTime = cookingTime
        self.ingredients = ingredients
        self.steps = steps
        self.categories = categories
        self.note = note
    }
}
