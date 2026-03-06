import Foundation
import MHPreferences

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

    private static var store: MHPreferenceStore {
        .init(userDefaults: userDefaults)
    }

    /// Reads a shared string preference.
    public static func string(for key: StringPreferenceKey) -> String? {
        store.string(for: key.preferenceKey)
    }

    /// Stores or removes a shared string preference.
    public static func set(_ value: String?, for key: StringPreferenceKey) {
        store.set(
            value,
            for: key.preferenceKey
        )
    }
}
