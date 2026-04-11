import MHPlatform
import SwiftUI

extension AppStorage {
    /// Creates a boolean app-storage binding using Cookle's shared app-group store by default.
    init(
        _ key: BoolPreferenceKey
    ) where Value == Bool {
        self.init(
            key.preferenceKey,
            selection: .suite(UserDefaults.appGroupIdentifier)
        )
    }

    /// Creates a boolean app-storage binding using an explicit store override.
    init(
        _ key: BoolPreferenceKey,
        store: UserDefaults
    ) where Value == Bool {
        self.init(
            key.preferenceKey,
            store: store
        )
    }

    /// Creates an integer app-storage binding using Cookle's shared app-group store by default.
    init(
        _ key: IntPreferenceKey
    ) where Value == Int {
        self.init(
            key,
            selection: .suite(UserDefaults.appGroupIdentifier)
        )
    }

    /// Creates an integer app-storage binding using an explicit store override.
    init(
        _ key: IntPreferenceKey,
        store: UserDefaults
    ) where Value == Int {
        self.init(
            key.preferenceKey(default: .zero),
            store: store
        )
    }

    /// Creates a string app-storage binding using Cookle's shared app-group store by default.
    init(
        _ key: StringPreferenceKey
    ) where Value == String {
        self.init(
            key,
            selection: .suite(UserDefaults.appGroupIdentifier)
        )
    }

    /// Creates a string app-storage binding using an explicit store override.
    init(
        _ key: StringPreferenceKey,
        store: UserDefaults
    ) where Value == String {
        self.init(
            key.preferenceKey,
            default: "",
            store: store
        )
    }
}
