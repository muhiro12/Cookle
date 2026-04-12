import MHPlatformCore

/// Stable storage keys for integer settings persisted in preferences.
public enum IntPreferenceKey: String, CaseIterable, Sendable, MHIntPrefDescriptorRepresentable {
    case dailyRecipeSuggestionHour = "r5Vn8Kt1"
    case dailyRecipeSuggestionMinute = "u7Bx3Jd6"
    case tipExperienceVersion = "t7Px9Nb4"

    public func preferenceDescriptor(
        default defaultValue: Int = .zero
    ) -> MHIntPreferenceDescriptor {
        .init(
            storageKey: rawValue,
            defaultSelection: .standard,
            default: defaultValue
        )
    }
}
