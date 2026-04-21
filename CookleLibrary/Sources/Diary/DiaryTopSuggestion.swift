import Foundation

/// Candidate used to start today's diary from the most relevant recent recipe.
public struct DiaryTopSuggestion: Equatable, Sendable {
    public let date: Date
    public let recipeName: String
    public let recipeStableIdentifier: String
    public let mealType: DiaryObjectType

    public init(
        date: Date,
        recipeName: String,
        recipeStableIdentifier: String,
        mealType: DiaryObjectType
    ) {
        self.date = date
        self.recipeName = recipeName
        self.recipeStableIdentifier = recipeStableIdentifier
        self.mealType = mealType
    }
}
