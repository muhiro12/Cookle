import MHPlatformCore

/// Stable namespaces for dynamic `Codable` preference keys.
public enum CodablePreferenceNamespace: String, Sendable {
    case formSnapshot = "cookle.formSnapshot"

    public func preferenceDescriptor<Value: Codable & Sendable>(
        name: String,
        defaultSelection: MHUserDefaultsSelection,
        _: Value.Type = Value.self
    ) -> MHCodablePreferenceDescriptor<Value> {
        .init(
            storageKey: storageKey(name: name),
            defaultSelection: defaultSelection
        )
    }

    public func storageKey(
        name: String
    ) -> String {
        "\(rawValue).\(name)"
    }
}
