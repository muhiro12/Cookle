import FoundationModels

/// Lightweight dish direction generated from ingredients without creating a full recipe.
@available(iOS 26.0, *)
@Generable(
    description: "A lightweight dish idea based on selected ingredients, not a full recipe."
)
public struct RecipeIdeaSuggestion: Equatable, Sendable {
    /// Short dish idea title.
    @Guide(
        description: "Short, inspiring dish idea title. Do not present it as a complete verified recipe."
    )
    public var title: String
    /// Flavor, cuisine, or meal direction.
    @Guide(
        description: "A short flavor, cuisine, or meal direction for the idea."
    )
    public var flavorDirection: String
    /// Rough cooking approach without detailed step-by-step instructions.
    @Guide(
        description: "One concise sentence describing the rough approach. Avoid detailed step-by-step instructions."
    )
    public var roughApproach: String
    /// Selected ingredients that anchor the idea.
    @Guide(
        description: "Only ingredients from the user's selected ingredient list that anchor this idea."
    )
    public var coreIngredients: [String]

    /// Creates a lightweight recipe idea suggestion.
    public init(
        title: String,
        flavorDirection: String,
        roughApproach: String,
        coreIngredients: [String]
    ) {
        self.title = title
        self.flavorDirection = flavorDirection
        self.roughApproach = roughApproach
        self.coreIngredients = coreIngredients
    }
}
