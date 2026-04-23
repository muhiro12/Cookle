import FoundationModels

/// Container used for structured ingredient idea generation.
@available(iOS 26.0, *)
@Generable(
    description: "A short list of lightweight dish ideas based on selected ingredients."
)
public struct RecipeIdeaSuggestionResponse {
    /// Suggested dish ideas.
    @Guide(
        description: "Two to four distinct dish ideas. Keep them inspirational and non-authoritative."
    )
    public var ideas: [RecipeIdeaSuggestion]

    /// Creates a generated response.
    public init(ideas: [RecipeIdeaSuggestion]) {
        self.ideas = ideas
    }
}
