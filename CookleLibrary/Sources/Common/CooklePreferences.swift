import Foundation

/// Boolean preference keys.
public enum BoolPreferenceKey: String {
    case isSubscribeOn = "qWeRty12"
    case isICloudOn = "AO9Yo1cC"
    case isDebugOn = "hd3fAy3G"
    case isDailyRecipeSuggestionNotificationOn = "m9Pq2Ls4"
}

/// String preference keys.
public enum StringPreferenceKey: String {
    case lastOpenedRecipeID = "zxcXvb12"
}

/// Integer preference keys.
public enum IntPreferenceKey: String {
    case dailyRecipeSuggestionHour = "r5Vn8Kt1"
    case dailyRecipeSuggestionMinute = "u7Bx3Jd6"
}

/// Thin wrapper around `UserDefaults` for app preferences.
public enum CooklePreferences {
    private static var userDefaults: UserDefaults {
        .standard
    }

    /// Reads a boolean preference value.
    public static func bool(for key: BoolPreferenceKey) -> Bool {
        userDefaults.bool(forKey: key.rawValue)
    }

    /// Writes a boolean preference value.
    public static func set(_ value: Bool, for key: BoolPreferenceKey) {
        userDefaults.set(value, forKey: key.rawValue)
    }

    /// Reads a string preference value.
    public static func string(for key: StringPreferenceKey) -> String? {
        userDefaults.string(forKey: key.rawValue)
    }

    /// Writes a string preference value (removes the key on `nil`).
    public static func set(_ value: String?, for key: StringPreferenceKey) {
        if let value {
            userDefaults.set(value, forKey: key.rawValue)
        } else {
            userDefaults.removeObject(forKey: key.rawValue)
        }
    }

    /// Reads an integer preference value.
    public static func int(for key: IntPreferenceKey) -> Int {
        userDefaults.integer(forKey: key.rawValue)
    }

    /// Reads an integer preference value, falling back when unset.
    public static func int(for key: IntPreferenceKey, default defaultValue: Int) -> Int {
        guard userDefaults.object(forKey: key.rawValue) != nil else {
            return defaultValue
        }
        return userDefaults.integer(forKey: key.rawValue)
    }

    /// Writes an integer preference value.
    public static func set(_ value: Int, for key: IntPreferenceKey) {
        userDefaults.set(value, forKey: key.rawValue)
    }
}
