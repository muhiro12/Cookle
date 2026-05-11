import Foundation

/// Best-effort recipe structure inferred from free-form text.
public struct RecipeInferenceResult: Equatable, Sendable {
    /// Recipe name.
    public var name: String
    /// Number of servings.
    public var servingSize: Int
    /// Cooking time in minutes.
    public var cookingTime: Int
    /// Ingredient/amount pairs.
    public var ingredients: [RecipeInferenceIngredient]
    /// Cooking steps.
    public var steps: [String]
    /// Category labels.
    public var categories: [String]
    /// Free-form note.
    public var note: String

    /// Creates an inferred recipe value.
    public init(
        name: String,
        servingSize: Int,
        cookingTime: Int,
        ingredients: [RecipeInferenceIngredient],
        steps: [String],
        categories: [String],
        note: String
    ) {
        self.name = name
        self.servingSize = servingSize
        self.cookingTime = cookingTime
        self.ingredients = ingredients
        self.steps = steps
        self.categories = categories
        self.note = note
    }
}
