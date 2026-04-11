import MHPlatformCore

/// Stable namespaces for dynamic `Codable` preference keys.
public enum CodablePreferenceNamespace: String {
    case formSnapshot = "cookle.formSnapshot"

    public func preferenceKey<Value: Codable & Sendable>(
        name: String,
        _: Value.Type = Value.self
    ) -> MHCodablePreferenceKey<Value> {
        .init(
            namespace: rawValue,
            name: name
        )
    }
}
