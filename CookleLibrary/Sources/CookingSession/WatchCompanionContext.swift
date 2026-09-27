import Foundation

/// Composes and reads the WatchConnectivity application context shared by
/// iPhone and Watch.
///
/// Application context replaces the previous dictionary on every update, so
/// each side keeps a single writer that always sends the complete context:
/// the cooking session state and, from iPhone, the recent recipe catalog.
/// The legacy snapshot key is never written, so an older peer cannot treat
/// new state as its last-writer-wins snapshot and create a second authority.
public enum WatchCompanionContext {
    /// The cooking session content of a received context.
    public enum SessionPayload: Equatable, Sendable {
        /// Nothing usable; keep local state.
        case absent
        /// Only the earlier snapshot contract; the peer needs an update.
        case legacyOnly
        /// A newer format this build cannot read; this device needs an update.
        case unsupported
        /// Unreadable; keep local state.
        case malformed
        /// A readable state to merge.
        case state(CookingSessionSyncState)
    }

    /// The key carrying the encoded cooking session state.
    public static let sessionStateKey = "cookingSessionState"
    /// The key carrying the encoded recent recipe catalog.
    public static let recentRecipeCatalogKey = "recentRecipeCatalog"
    /// The key an earlier build used for its snapshot-only contract.
    public static let legacySnapshotKey = "activeCookingSessionSnapshot"

    /// Classifies the cooking session content of a received context.
    public static func sessionPayload(
        in context: [String: Any]
    ) -> SessionPayload {
        if let encodedState = context[sessionStateKey] as? String {
            switch CookingSessionSyncState.decoding(encodedState) {
            case .decoded(let state):
                return .state(state)
            case .unsupported:
                return .unsupported
            case .malformed:
                return .malformed
            }
        }
        if let legacySnapshot = context[legacySnapshotKey] as? String,
           legacySnapshot.isEmpty == false {
            return .legacyOnly
        }
        return .absent
    }

    /// Returns the received catalog, or `nil` when the context carries no
    /// usable catalog and the receiver should keep its last accepted one.
    public static func recentRecipeCatalog(
        in context: [String: Any]
    ) -> RecentRecipeCatalog? {
        guard let encodedCatalog = context[recentRecipeCatalogKey] as? String else {
            return nil
        }
        return RecentRecipeCatalog.decoded(from: encodedCatalog)
    }

    /// Builds the complete context this side sends.
    public static func composed(
        sessionState: CookingSessionSyncState,
        recentRecipeCatalog: RecentRecipeCatalog? = nil
    ) -> [String: Any] {
        var context = [String: Any]()
        if let encodedState = sessionState.encodedString() {
            context[sessionStateKey] = encodedState
        }
        if let encodedCatalog = recentRecipeCatalog?.encodedString() {
            context[recentRecipeCatalogKey] = encodedCatalog
        }
        return context
    }
}
