import Foundation
import MHPlatformCore

/// Stable storage keys for integer settings persisted in app-local preferences.
public enum IntPreferenceKey: String, MHIntPreferenceKeyRepresentable {
    case dailyRecipeSuggestionHour = "r5Vn8Kt1"
    case dailyRecipeSuggestionMinute = "u7Bx3Jd6"
    case tipExperienceVersion = "t7Px9Nb4"

    public func preferenceKey(default defaultValue: Int = .zero) -> MHIntPreferenceKey {
        .init(
            storageKey: rawValue,
            default: defaultValue
        )
    }
}
