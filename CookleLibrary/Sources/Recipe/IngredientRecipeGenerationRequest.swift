import Foundation

/// Input used to generate a recipe from selected ingredients.
@available(iOS 26.0, *)
public struct IngredientRecipeGenerationRequest: Sendable {
    public let availableIngredients: [String]
    public let additionalInstructions: String

    public init(
        availableIngredients: [String],
        additionalInstructions: String
    ) {
        self.availableIngredients = availableIngredients
        self.additionalInstructions = additionalInstructions
    }
}
