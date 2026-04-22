/// Normalized recipe content passed into Image Playground.
public struct RecipeImageConceptDraft: Sendable {
    public let title: String
    public let ingredients: [String]
    /// Optional finish- or plating-oriented steps used to keep image generation focused on the completed dish.
    public let combinedSteps: String?

    public init(
        title: String,
        ingredients: [String],
        combinedSteps: String?
    ) {
        self.title = title
        self.ingredients = ingredients
        self.combinedSteps = combinedSteps
    }
}
