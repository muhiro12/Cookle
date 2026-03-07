import SwiftUI

extension AppStorage {
    /// Creates a boolean app-storage binding for the given storage key.
    init(
        _ key: BoolPreferenceKey,
        store: UserDefaults = .standard
    ) where Value == Bool {
        self.init(
            key.preferenceKey,
            store: store
        )
    }

    /// Creates an integer app-storage binding for the given storage key.
    init(
        _ key: IntPreferenceKey,
        store: UserDefaults = .standard
    ) where Value == Int {
        self.init(
            key.preferenceKey(default: .zero),
            store: store
        )
    }

    /// Creates a string app-storage binding for the given storage key.
    init(
        _ key: StringPreferenceKey,
        store: UserDefaults = .standard
    ) where Value == String {
        self.init(
            key.preferenceKey,
            default: "",
            store: store
        )
    }
}
