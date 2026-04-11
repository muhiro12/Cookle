import Foundation

public extension UserDefaults {
    /// The app group identifier used for shared `UserDefaults` access.
    static var appGroupIdentifier: String {
        AppGroup.id
    }

    /// Shared `UserDefaults` configured for the app group with legacy migration.
    static var shared: UserDefaults {
        let userDefaults = UserDefaults(
            suiteName: appGroupIdentifier
        ) ?? .standard
        if userDefaults.bool(
            for: .hasMigratedLegacyPreferences
        ) == false {
            migrateLegacyPreferenceValuesIfNeeded(
                to: userDefaults,
                from: .standard
            )
            userDefaults.set(true, for: .hasMigratedLegacyPreferences)
        }
        return userDefaults
    }
}

private extension UserDefaults {
    static func migrateLegacyPreferenceValuesIfNeeded(
        to sharedUserDefaults: UserDefaults,
        from legacyUserDefaults: UserDefaults
    ) {
        migrate(
            keys: BoolPreferenceKey.allCases.map(\.rawValue),
            to: sharedUserDefaults,
            from: legacyUserDefaults
        )
        migrate(
            keys: IntPreferenceKey.allCases.map(\.rawValue),
            to: sharedUserDefaults,
            from: legacyUserDefaults
        )
        migrate(
            keys: StringPreferenceKey.allCases.map(\.rawValue),
            to: sharedUserDefaults,
            from: legacyUserDefaults
        )
    }

    static func migrate(
        keys: [String],
        to sharedUserDefaults: UserDefaults,
        from legacyUserDefaults: UserDefaults
    ) {
        for key in keys {
            guard sharedUserDefaults.object(forKey: key) == nil,
                  let value = legacyUserDefaults.object(forKey: key) else {
                continue
            }
            sharedUserDefaults.set(
                value,
                forKey: key
            )
        }
    }
}

private extension UserDefaults {
    func bool(
        for key: BoolPreferenceKey
    ) -> Bool {
        bool(
            forKey: key.preferenceKey.storageKey
        )
    }

    func set(
        _ value: Bool,
        for key: BoolPreferenceKey
    ) {
        set(
            value,
            forKey: key.preferenceKey.storageKey
        )
    }
}
