/// Ingredient input used in recipe form flows.
public struct RecipeFormIngredientInput: Sendable {
    public var ingredient: String
    public var amount: String

    public init(
        ingredient: String,
        amount: String
    ) {
        self.ingredient = ingredient
        self.amount = amount
    }
}
