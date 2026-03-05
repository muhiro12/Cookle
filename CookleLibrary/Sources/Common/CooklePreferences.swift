import Foundation

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
