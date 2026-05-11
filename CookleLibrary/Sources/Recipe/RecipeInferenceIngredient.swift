import Foundation

/// Ingredient/amount pair extracted from recipe-like text.
public struct RecipeInferenceIngredient: Equatable, Sendable {
    /// Ingredient name.
    public var ingredient: String
    /// Human-readable amount.
    public var amount: String

    /// Creates an inferred ingredient entry.
    public init(ingredient: String, amount: String) {
        self.ingredient = ingredient
        self.amount = amount
    }
}
