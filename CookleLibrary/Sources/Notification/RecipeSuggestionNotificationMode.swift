import Foundation

/// The app preference is independent of system notification permission.
public enum RecipeSuggestionNotificationMode: String, CaseIterable, Codable, Sendable {
    case off
    case fixed
    case adaptive

    /// Resolves an upgrade from persistent keys, excluding registered defaults.
    public static func migratedValue(
        from persistentValues: [String: Any]
    ) -> Self {
        typealias Key = CookleUserDefaultsKeys.Standard
        if let rawValue = persistentValues[Key.recipeSuggestionNotificationMode.rawValue] as? String,
           let mode = Self(rawValue: rawValue) {
            return mode
        }
        if let wasEnabled = persistentValues[Key.isDailyRecipeSuggestionNotificationOn.rawValue] as? Bool {
            return wasEnabled ? .fixed : .off
        }
        let legacyKeys: [Key] = [
            .lastLaunchedAppVersion,
            .dailyRecipeSuggestionHour,
            .dailyRecipeSuggestionMinute
        ]
        return legacyKeys.contains { persistentValues[$0.rawValue] != nil } ? .off : .adaptive
    }
}
