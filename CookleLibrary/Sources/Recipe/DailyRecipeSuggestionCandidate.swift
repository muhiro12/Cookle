import Foundation

/// Candidate used to generate daily suggestion schedules.
public struct DailyRecipeSuggestionCandidate: Sendable {
    public let name: String
    public let stableIdentifier: String
    public let isFavorite: Bool
    public let hasPhoto: Bool
    public let ingredientCount: Int
    public let cookingTime: Int
    public let madeCount: Int
    public let lastCookedDate: Date?

    public init(
        name: String,
        stableIdentifier: String,
        isFavorite: Bool = false,
        hasPhoto: Bool = false,
        ingredientCount: Int = .zero,
        cookingTime: Int = .zero,
        madeCount: Int = .zero,
        lastCookedDate: Date? = nil
    ) {
        self.name = name
        self.stableIdentifier = stableIdentifier
        self.isFavorite = isFavorite
        self.hasPhoto = hasPhoto
        self.ingredientCount = ingredientCount
        self.cookingTime = cookingTime
        self.madeCount = madeCount
        self.lastCookedDate = lastCookedDate
    }
}
