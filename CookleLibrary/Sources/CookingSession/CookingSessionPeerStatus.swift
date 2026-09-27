/// Whether the paired peer can take part in cooking session sync.
public enum CookingSessionPeerStatus: Equatable, Sendable {
    case compatible
    /// The peer still uses the earlier snapshot contract.
    case peerRequiresUpdate
    /// The peer sent a newer format than this build understands.
    case thisDeviceRequiresUpdate
}
