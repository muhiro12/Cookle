import Foundation

/// A reviewed choice between two independently started sessions.
///
/// Choosing a session is distinct from ending it. Concurrent opposite choices
/// use a logical revision and editor tie-break, so they select one session
/// instead of turning both choices into irreversible end records.
public struct CookingSessionResolution: Codable, Equatable, Sendable {
    /// First session in canonical identifier order.
    public let first: CookingSessionID
    /// Second session in canonical identifier order.
    public let second: CookingSessionID
    /// The session selected by this decision.
    public let winner: CookingSessionID
    /// Logical decision revision.
    public let revision: Int
    /// Install that made the choice.
    public let editorID: String

    var isValid: Bool {
        first.isValid && second.isValid && first != second
            && (winner == first || winner == second)
            && !editorID.isEmpty && revision > 0 && revision < CookingSessionID.maximumCounter
    }

    /// Records a canonical ordered pair and its selected session.
    public init(
        first: CookingSessionID,
        second: CookingSessionID,
        winner: CookingSessionID,
        revision: Int,
        editorID: String
    ) {
        let firstComesBefore = first.originID == second.originID
            ? first.sequence < second.sequence : first.originID < second.originID
        self.first = firstComesBefore ? first : second
        self.second = firstComesBefore ? second : first
        self.winner = winner
        self.revision = revision
        self.editorID = editorID
    }

    func matches(_ other: Self) -> Bool {
        first == other.first && second == other.second
    }

    func supersedes(_ other: Self) -> Bool {
        revision == other.revision ? editorID > other.editorID : revision > other.revision
    }

    func excludes(_ sessionID: CookingSessionID) -> Bool {
        (sessionID == first || sessionID == second) && sessionID != winner
    }
}
