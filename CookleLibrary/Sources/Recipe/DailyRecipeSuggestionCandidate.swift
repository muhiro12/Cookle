/// Candidate used to generate daily suggestion schedules.
public struct DailyRecipeSuggestionCandidate: Sendable {
    public let name: String
    public let stableIdentifier: String

    public init(
        name: String,
        stableIdentifier: String
    ) {
        self.name = name
        self.stableIdentifier = stableIdentifier
    }
}
