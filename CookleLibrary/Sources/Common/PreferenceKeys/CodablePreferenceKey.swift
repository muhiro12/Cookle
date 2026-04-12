import MHPlatformCore

/// Stable storage keys for `Codable` values persisted in preferences.
public enum CodablePreferenceKey: String, CaseIterable, Sendable {
    case loggingCurrentSession = "J4mK7pXd"
    case loggingPreviousSession = "Q9tB3cLf"
    case diaryFormSnapshot = "W6yH1nRu"
    case recipeFormSnapshot = "E8kP5sZa"

    public func preferenceDescriptor<Value: Codable & Sendable>(
        _: Value.Type = Value.self
    ) -> MHCodablePreferenceDescriptor<Value> {
        .init(
            storageKey: rawValue,
            defaultSelection: .standard
        )
    }
}
