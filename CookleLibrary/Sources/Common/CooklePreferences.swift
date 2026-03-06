import Foundation
import MHPreferences

/// Thin wrapper around `UserDefaults` for app preferences.
public enum CooklePreferences {
    private static var store: MHPreferenceStore {
        .init(userDefaults: .standard)
    }

    /// Reads a boolean preference value.
    public static func bool(for key: BoolPreferenceKey) -> Bool {
        store.bool(for: key.preferenceKey)
    }

    /// Writes a boolean preference value.
    public static func set(_ value: Bool, for key: BoolPreferenceKey) {
        store.set(
            value,
            for: key.preferenceKey
        )
    }

    /// Reads a string preference value.
    public static func string(for key: StringPreferenceKey) -> String? {
        store.string(for: key.preferenceKey)
    }

    /// Writes a string preference value (removes the key on `nil`).
    public static func set(_ value: String?, for key: StringPreferenceKey) {
        store.set(
            value,
            for: key.preferenceKey
        )
    }

    /// Reads an integer preference value.
    public static func int(for key: IntPreferenceKey) -> Int {
        store.int(for: key.preferenceKey())
    }

    /// Reads an integer preference value, falling back when unset.
    public static func int(for key: IntPreferenceKey, default defaultValue: Int) -> Int {
        store.int(
            for: key.preferenceKey(default: defaultValue)
        )
    }

    /// Writes an integer preference value.
    public static func set(_ value: Int, for key: IntPreferenceKey) {
        store.set(
            value,
            for: key.preferenceKey()
        )
    }

    /// Returns whether an integer preference has a stored value.
    public static func contains(_ key: IntPreferenceKey) -> Bool {
        store.contains(key.preferenceKey())
    }
}
