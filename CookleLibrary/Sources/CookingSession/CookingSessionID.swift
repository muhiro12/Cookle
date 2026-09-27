import Foundation

/// Identifies one cooking session by the install that started it and that
/// install's monotonically increasing start sequence.
///
/// Every start creates a new identifier, even for the same recipe, so a
/// delayed update from an earlier session can never be mistaken for the
/// current one.
public struct CookingSessionID: Codable, Hashable, Sendable {
    /// The per-install identifier of the device that started the session.
    public let originID: String
    /// The start sequence of the session on its origin install.
    public let sequence: Int

    public init(
        originID: String,
        sequence: Int
    ) {
        self.originID = originID
        self.sequence = sequence
    }
}
