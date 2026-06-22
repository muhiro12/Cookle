import Foundation
import MHPlatformCore

/// Preference accessors backed by each descriptor's default `UserDefaults` selection.
public enum CooklePreferences {
    private static var store: MHPreferenceStore {
        .init()
    }

    /// Returns the stored boolean value for the supplied app-local setting.
    public static func bool(
        for keyPath: KeyPath<MHPreferenceDescriptors, MHBoolPreferenceDescriptor>
    ) -> Bool {
        store.bool(for: keyPath)
    }

    /// Persists a boolean value for the supplied app-local setting.
    public static func set(
        _ value: Bool,
        for keyPath: KeyPath<MHPreferenceDescriptors, MHBoolPreferenceDescriptor>
    ) {
        store.set(
            value,
            for: keyPath
        )
    }

    /// Returns the stored string value for the supplied app-local setting.
    public static func string(
        for keyPath: KeyPath<MHPreferenceDescriptors, MHStringPreferenceDescriptor>
    ) -> String? {
        store.string(for: keyPath)
    }

    /// Persists a string value for the supplied app-local setting, removing it when `nil`.
    public static func set(
        _ value: String?,
        for keyPath: KeyPath<MHPreferenceDescriptors, MHStringPreferenceDescriptor>
    ) {
        store.set(
            value,
            for: keyPath
        )
    }

    /// Returns the stored integer value using the key's built-in default when unset.
    public static func int(
        for keyPath: KeyPath<MHPreferenceDescriptors, MHIntPreferenceDescriptor>
    ) -> Int {
        store.int(for: keyPath)
    }

    /// Returns the stored integer value, or `defaultValue` when the key has no stored value.
    public static func int(
        for keyPath: KeyPath<MHPreferenceDescriptors, MHIntPreferenceDescriptor>,
        default defaultValue: Int
    ) -> Int {
        store.int(
            for: keyPath,
            default: defaultValue
        )
    }

    /// Persists an integer value for the supplied app-local setting.
    public static func set(
        _ value: Int,
        for keyPath: KeyPath<MHPreferenceDescriptors, MHIntPreferenceDescriptor>
    ) {
        store.set(
            value,
            for: keyPath
        )
    }

    /// Returns whether the supplied integer setting has an explicit stored value.
    public static func contains<Descriptor: MHStorageDescriptorProtocol>(
        _ keyPath: KeyPath<MHPreferenceDescriptors, Descriptor>
    ) -> Bool {
        store.contains(
            MHPreferenceDescriptors()[keyPath: keyPath]
        )
    }
}
