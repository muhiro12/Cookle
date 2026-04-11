@testable import CookleLibrary
import Foundation
import Testing

@Suite(.serialized)
struct UserDefaultsCookleSharedTests {
    private enum Keys {
        static let bool = BoolPreferenceKey.isSubscribeOn
        static let int = IntPreferenceKey.tipExperienceVersion
        static let string = StringPreferenceKey.pendingIntentDeepLinkURL
        static let migrationMarker = BoolPreferenceKey.hasMigratedLegacyPreferences

        static let storageKeys = [
            bool.rawValue,
            int.rawValue,
            string.rawValue,
            migrationMarker.rawValue
        ]
    }

    @Test
    func migratesLegacyPrimitivePreferencesIntoSharedStore() throws {
        let sharedDefaults = try makeSharedSuiteUserDefaults()
        let standardDefaults = UserDefaults.standard
        let sharedSnapshot = makeSnapshot(
            in: sharedDefaults,
            keys: Keys.storageKeys
        )
        let standardSnapshot = makeSnapshot(
            in: standardDefaults,
            keys: Keys.storageKeys
        )
        defer {
            restore(sharedSnapshot, to: sharedDefaults)
            restore(standardSnapshot, to: standardDefaults)
        }

        clear(Keys.storageKeys, in: sharedDefaults)
        clear(Keys.storageKeys, in: standardDefaults)

        standardDefaults.set(true, forKey: Keys.bool.rawValue)
        standardDefaults.set(18, forKey: Keys.int.rawValue)
        standardDefaults.set("2.10", forKey: Keys.string.rawValue)

        let migratedDefaults = UserDefaults.shared

        #expect(migratedDefaults.bool(forKey: Keys.bool.rawValue))
        #expect(migratedDefaults.integer(forKey: Keys.int.rawValue) == 18)
        #expect(migratedDefaults.string(forKey: Keys.string.rawValue) == "2.10")
        #expect(migratedDefaults.bool(forKey: Keys.migrationMarker.rawValue))
    }

    @Test
    func sharedValuesAreNotOverwrittenDuringMigration() throws {
        let sharedDefaults = try makeSharedSuiteUserDefaults()
        let standardDefaults = UserDefaults.standard
        let sharedSnapshot = makeSnapshot(
            in: sharedDefaults,
            keys: Keys.storageKeys
        )
        let standardSnapshot = makeSnapshot(
            in: standardDefaults,
            keys: Keys.storageKeys
        )
        defer {
            restore(sharedSnapshot, to: sharedDefaults)
            restore(standardSnapshot, to: standardDefaults)
        }

        clear(Keys.storageKeys, in: sharedDefaults)
        clear(Keys.storageKeys, in: standardDefaults)

        sharedDefaults.set(false, forKey: Keys.bool.rawValue)
        sharedDefaults.set(7, forKey: Keys.int.rawValue)
        sharedDefaults.set("shared", forKey: Keys.string.rawValue)

        standardDefaults.set(true, forKey: Keys.bool.rawValue)
        standardDefaults.set(22, forKey: Keys.int.rawValue)
        standardDefaults.set("legacy", forKey: Keys.string.rawValue)

        let migratedDefaults = UserDefaults.shared

        #expect(migratedDefaults.bool(forKey: Keys.bool.rawValue) == false)
        #expect(migratedDefaults.integer(forKey: Keys.int.rawValue) == 7)
        #expect(migratedDefaults.string(forKey: Keys.string.rawValue) == "shared")
        #expect(migratedDefaults.bool(forKey: Keys.migrationMarker.rawValue))
    }

    @Test
    func migrationRunsOnlyOnceAfterMarkerIsStored() throws {
        let sharedDefaults = try makeSharedSuiteUserDefaults()
        let standardDefaults = UserDefaults.standard
        let sharedSnapshot = makeSnapshot(
            in: sharedDefaults,
            keys: Keys.storageKeys
        )
        let standardSnapshot = makeSnapshot(
            in: standardDefaults,
            keys: Keys.storageKeys
        )
        defer {
            restore(sharedSnapshot, to: sharedDefaults)
            restore(standardSnapshot, to: standardDefaults)
        }

        clear(Keys.storageKeys, in: sharedDefaults)
        clear(Keys.storageKeys, in: standardDefaults)

        standardDefaults.set(true, forKey: Keys.bool.rawValue)
        standardDefaults.set(9, forKey: Keys.int.rawValue)
        standardDefaults.set("first-pass", forKey: Keys.string.rawValue)

        _ = UserDefaults.shared

        standardDefaults.set(false, forKey: Keys.bool.rawValue)
        standardDefaults.set(3, forKey: Keys.int.rawValue)
        standardDefaults.set("second-pass", forKey: Keys.string.rawValue)

        let migratedDefaults = UserDefaults.shared

        #expect(migratedDefaults.bool(forKey: Keys.bool.rawValue))
        #expect(migratedDefaults.integer(forKey: Keys.int.rawValue) == 9)
        #expect(migratedDefaults.string(forKey: Keys.string.rawValue) == "first-pass")
        #expect(migratedDefaults.bool(forKey: Keys.migrationMarker.rawValue))
    }
}

private extension UserDefaultsCookleSharedTests {
    struct DefaultsSnapshot {
        let presentValues: [String: Any]
        let missingKeys: Set<String>
    }

    func makeSharedSuiteUserDefaults() throws -> UserDefaults {
        try #require(
            UserDefaults(
                suiteName: UserDefaults.appGroupIdentifier
            )
        )
    }

    func makeSnapshot(
        in userDefaults: UserDefaults,
        keys: [String]
    ) -> DefaultsSnapshot {
        var presentValues: [String: Any] = [:]
        var missingKeys: Set<String> = []

        for key in keys {
            if let value = userDefaults.object(forKey: key) {
                presentValues[key] = value
            } else {
                missingKeys.insert(key)
            }
        }

        return .init(
            presentValues: presentValues,
            missingKeys: missingKeys
        )
    }

    func clear(
        _ keys: [String],
        in userDefaults: UserDefaults
    ) {
        for key in keys {
            userDefaults.removeObject(forKey: key)
        }
    }

    func restore(
        _ snapshot: DefaultsSnapshot,
        to userDefaults: UserDefaults
    ) {
        for key in snapshot.missingKeys {
            userDefaults.removeObject(forKey: key)
        }
        for (key, value) in snapshot.presentValues {
            userDefaults.set(value, forKey: key)
        }
    }
}
