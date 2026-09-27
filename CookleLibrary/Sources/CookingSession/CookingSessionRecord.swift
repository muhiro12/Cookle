import Foundation

/// A cooking session snapshot with the identity and logical revision used to
/// order changes without trusting device clocks.
public struct CookingSessionRecord: Codable, Equatable, Sendable {
    /// The session this record belongs to.
    public let sessionID: CookingSessionID
    /// The logical revision within the session; each local change increments it.
    public let revision: Int
    /// The install that produced this revision; breaks revision ties.
    public let editorID: String
    /// The session content, progress, and timer.
    public let snapshot: CookingSessionSnapshot

    var isValid: Bool {
        sessionID.isValid && !editorID.isEmpty && revision > 0 && revision < CookingSessionID.maximumCounter
    }

    public init(
        sessionID: CookingSessionID,
        revision: Int,
        editorID: String,
        snapshot: CookingSessionSnapshot
    ) {
        self.sessionID = sessionID
        self.revision = revision
        self.editorID = editorID
        self.snapshot = snapshot
    }

    /// Returns a new revision of this session edited by `editorID`.
    public func revised(
        with snapshot: CookingSessionSnapshot,
        editorID: String
    ) -> Self {
        .init(
            sessionID: sessionID,
            revision: revision + 1,
            editorID: editorID,
            snapshot: snapshot
        )
    }

    /// Whether this record orders after `other` for the same session.
    ///
    /// An ended revision always wins so that an end is never undone by a
    /// delayed active revision. Otherwise the higher revision wins and the
    /// editor identifier breaks ties deterministically.
    func supersedes(
        _ other: Self
    ) -> Bool {
        if snapshot.isActive != other.snapshot.isActive {
            return snapshot.isActive == false
        }
        if revision != other.revision {
            return revision > other.revision
        }
        return editorID > other.editorID
    }
}
