import MHPlatformCore

/// Stable storage keys for `Codable` values persisted in preferences.
public enum CodablePreferenceKey: String, Sendable {
    case loggingLastSession = "cookle.logging.last-session"

    public func preferenceKey<Value: Codable & Sendable>(
        _: Value.Type = Value.self
    ) -> MHCodablePreferenceKey<Value> {
        .init(storageKey: rawValue)
    }
}
