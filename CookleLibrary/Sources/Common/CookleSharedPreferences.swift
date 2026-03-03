import Foundation

/// Shared preferences stored in the app-group container.
public enum CookleSharedPreferences {
    /// App-group identifier shared between the app and extensions.
    public static let appGroupIdentifier: String = "group.com.muhiro12.Cookle"

    private static var userDefaults: UserDefaults {
        if let sharedUserDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            return sharedUserDefaults
        }
        return .standard
    }

    /// Reads a shared string preference.
    public static func string(for key: StringPreferenceKey) -> String? {
        userDefaults.string(forKey: key.rawValue)
    }

    /// Stores or removes a shared string preference.
    public static func set(_ value: String?, for key: StringPreferenceKey) {
        if let value {
            userDefaults.set(value, forKey: key.rawValue)
        } else {
            userDefaults.removeObject(forKey: key.rawValue)
        }
    }
}
