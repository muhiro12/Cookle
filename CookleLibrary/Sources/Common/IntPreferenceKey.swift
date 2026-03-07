import Foundation
import MHPreferences

/// Stable storage keys for integer settings persisted in app-local preferences.
public enum IntPreferenceKey: String {
    case dailyRecipeSuggestionHour = "r5Vn8Kt1"
    case dailyRecipeSuggestionMinute = "u7Bx3Jd6"

    public func preferenceKey(default defaultValue: Int = .zero) -> MHIntPreferenceKey {
        .init(
            storageKey: rawValue,
            default: defaultValue
        )
    }
}
