import Foundation
import MHPlatformCore

/// Shared preference accessors backed by the app-group `UserDefaults` suite.
public enum CookleSharedPreferences {
    /// App-group suite name used by the app and its extensions.
    public static let appGroupIdentifier = UserDefaults.appGroupIdentifier

    private static var userDefaults: UserDefaults {
        MHUserDefaultsSelection
            .suite(appGroupIdentifier)
            .resolveUserDefaults()
    }

    private static var store: MHPreferenceStore {
        .init(userDefaults: userDefaults)
    }

    /// Returns the shared string value visible to both the app and extensions.
    public static func string(
        for keyPath: KeyPath<MHPreferenceDescriptors, MHStringPreferenceDescriptor>
    ) -> String? {
        store.string(
            for: MHPreferenceDescriptors()[keyPath: keyPath]
        )
    }

    /// Persists or removes a shared string value in the app-group container.
    public static func set(
        _ value: String?,
        for keyPath: KeyPath<MHPreferenceDescriptors, MHStringPreferenceDescriptor>
    ) {
        store.set(
            value,
            for: MHPreferenceDescriptors()[keyPath: keyPath]
        )
    }
}
