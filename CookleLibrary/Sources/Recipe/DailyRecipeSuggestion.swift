import Foundation

/// Computed daily suggestion schedule entry.
public struct DailyRecipeSuggestion: Sendable {
    public let identifier: String
    public let recipeName: String
    public let stableIdentifier: String
    public let notifyDate: Date

    public init(
        identifier: String,
        recipeName: String,
        stableIdentifier: String,
        notifyDate: Date
    ) {
        self.identifier = identifier
        self.recipeName = recipeName
        self.stableIdentifier = stableIdentifier
        self.notifyDate = notifyDate
    }
}
