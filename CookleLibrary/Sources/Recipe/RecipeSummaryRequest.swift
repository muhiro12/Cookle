import Foundation

/// Input used to summarize a recipe for compact list previews.
@available(iOS 26.0, *)
public struct RecipeSummaryRequest: Sendable {
    public let name: String
    public let ingredients: [String]
    public let steps: [String]
    public let categories: [String]
    public let note: String

    public init(
        name: String,
        ingredients: [String],
        steps: [String],
        categories: [String],
        note: String
    ) {
        self.name = name
        self.ingredients = ingredients
        self.steps = steps
        self.categories = categories
        self.note = note
    }
}
