import Foundation

public enum CookleSharedPreferences {
    public static let appGroupIdentifier: String = "group.com.muhiro12.Cookle"

    private static var userDefaults: UserDefaults {
        if let sharedUserDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            return sharedUserDefaults
        }
        return .standard
    }

    public static func string(for key: StringPreferenceKey) -> String? {
        userDefaults.string(forKey: key.rawValue)
    }

    public static func set(_ value: String?, for key: StringPreferenceKey) {
        if let value {
            userDefaults.set(value, forKey: key.rawValue)
        } else {
            userDefaults.removeObject(forKey: key.rawValue)
        }
    }
}
