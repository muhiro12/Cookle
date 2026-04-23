import FoundationModels

/// Temporary quick-view representation of an existing recipe.
@available(iOS 26.0, *)
@Generable(
    description: "A shortened view of an existing recipe. It is not saved back to the original recipe."
)
public struct QuickRecipeVersion: Equatable, Sendable {
    /// Short explanation of how the recipe was simplified.
    @Guide(
        description: "One concise sentence explaining the simplification."
    )
    public var summary: String
    /// Estimated quick cooking time in minutes. Use 0 when unknown.
    @Guide(
        description: "Estimated shortened cooking time in minutes. Use 0 when unknown."
    )
    public var estimatedCookingTime: Int
    /// Condensed cooking steps.
    @Guide(
        description: "Fewer, shorter steps than the original. Do not add unsupported ingredients or techniques."
    )
    public var steps: [String]

    /// Creates a temporary quick recipe version.
    public init(
        summary: String,
        estimatedCookingTime: Int,
        steps: [String]
    ) {
        self.summary = summary
        self.estimatedCookingTime = estimatedCookingTime
        self.steps = steps
    }
}
