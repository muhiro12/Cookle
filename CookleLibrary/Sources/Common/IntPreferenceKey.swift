import Foundation
import MHPreferences

/// Integer preference keys.
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
