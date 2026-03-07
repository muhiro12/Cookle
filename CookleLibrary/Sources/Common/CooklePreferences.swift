import Foundation
import MHPreferences

/// App-local preference accessors backed by standard `UserDefaults`.
public enum CooklePreferences {
    private static var store: MHPreferenceStore {
        .init(userDefaults: .standard)
    }

    /// Returns the stored boolean value for the supplied app-local setting.
    public static func bool(for key: BoolPreferenceKey) -> Bool {
        store.bool(for: key.preferenceKey)
    }

    /// Persists a boolean value for the supplied app-local setting.
    public static func set(_ value: Bool, for key: BoolPreferenceKey) {
        store.set(
            value,
            for: key.preferenceKey
        )
    }

    /// Returns the stored string value for the supplied app-local setting.
    public static func string(for key: StringPreferenceKey) -> String? {
        store.string(for: key.preferenceKey)
    }

    /// Persists a string value for the supplied app-local setting, removing it when `nil`.
    public static func set(_ value: String?, for key: StringPreferenceKey) {
        store.set(
            value,
            for: key.preferenceKey
        )
    }

    /// Returns the stored integer value using the key's built-in default when unset.
    public static func int(for key: IntPreferenceKey) -> Int {
        store.int(for: key.preferenceKey())
    }

    /// Returns the stored integer value, or `defaultValue` when the key has no stored value.
    public static func int(for key: IntPreferenceKey, default defaultValue: Int) -> Int {
        store.int(
            for: key.preferenceKey(default: defaultValue)
        )
    }

    /// Persists an integer value for the supplied app-local setting.
    public static func set(_ value: Int, for key: IntPreferenceKey) {
        store.set(
            value,
            for: key.preferenceKey()
        )
    }

    /// Returns whether the supplied integer setting has an explicit stored value.
    public static func contains(_ key: IntPreferenceKey) -> Bool {
        store.contains(key.preferenceKey())
    }
}
