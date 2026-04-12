import MHPlatformCore

/// Stable storage keys for `Codable` values persisted in preferences.
public enum CodablePreferenceKey: String, Sendable {
    case loggingLastSession = "cookle.logging.last-session"

    public func preferenceDescriptor<Value: Codable & Sendable>(
        defaultSelection: MHUserDefaultsSelection,
        _: Value.Type = Value.self
    ) -> MHCodablePreferenceDescriptor<Value> {
        .init(
            storageKey: rawValue,
            defaultSelection: defaultSelection
        )
    }

    public func storageKey(
        suffix: String
    ) -> String {
        "\(rawValue).\(suffix)"
    }
}
