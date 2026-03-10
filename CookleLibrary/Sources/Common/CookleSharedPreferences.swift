import Foundation
import MHPlatform

/// Shared preference accessors backed by the app-group `UserDefaults` suite.
public enum CookleSharedPreferences {
    /// App-group suite name used by the app and its extensions.
    public static let appGroupIdentifier: String = "group.com.muhiro12.Cookle"

    private static var userDefaults: UserDefaults {
        if let sharedUserDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            return sharedUserDefaults
        }
        return .standard
    }

    private static var store: MHPreferenceStore {
        .init(userDefaults: userDefaults)
    }

    /// Returns the shared string value visible to both the app and extensions.
    public static func string(for key: StringPreferenceKey) -> String? {
        store.string(for: key.preferenceKey)
    }

    /// Persists or removes a shared string value in the app-group container.
    public static func set(_ value: String?, for key: StringPreferenceKey) {
        store.set(
            value,
            for: key.preferenceKey
        )
    }
}
