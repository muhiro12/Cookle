import Foundation

public extension CooklePreferences {
    /// The persisted app mode; fresh installations prefer adaptive timing.
    static var suggestionNotificationMode: RecipeSuggestionNotificationMode {
        RecipeSuggestionNotificationMode(
            rawValue: string(for: \.recipeSuggestionNotificationMode) ?? ""
        ) ?? .adaptive
    }

    /// Run before recording the current app version or constructing services.
    /// Only the persistent domain distinguishes a new install from legacy Off.
    @discardableResult
    static func migrateSuggestionNotificationMode(
        domainName: String,
        in defaults: UserDefaults = .standard
    ) -> RecipeSuggestionNotificationMode {
        let values = defaults.persistentDomain(forName: domainName) ?? [:]
        let mode = RecipeSuggestionNotificationMode.migratedValue(from: values)
        let key = CookleUserDefaultsKeys.Standard.recipeSuggestionNotificationMode.rawValue
        if values[key] as? String != mode.rawValue {
            defaults.set(mode.rawValue, forKey: key)
        }
        return mode
    }
}
