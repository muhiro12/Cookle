@testable import CookleLibrary
import Foundation
import Testing

struct RecipeSuggestionNotificationModeTests {
    private typealias Key = CookleUserDefaultsKeys.Standard

    @Test
    func migration_usesPersistentLegacyChoiceAndVersion() {
        #expect(RecipeSuggestionNotificationMode.migratedValue(from: [:]) == .adaptive)
        #expect(RecipeSuggestionNotificationMode.migratedValue(
            from: [Key.isDailyRecipeSuggestionNotificationOn.rawValue: true]
        ) == .fixed)
        #expect(RecipeSuggestionNotificationMode.migratedValue(
            from: [Key.isDailyRecipeSuggestionNotificationOn.rawValue: false]
        ) == .off)
        #expect(RecipeSuggestionNotificationMode.migratedValue(
            from: [Key.lastLaunchedAppVersion.rawValue: "4.0"]
        ) == .off)
        #expect(RecipeSuggestionNotificationMode.migratedValue(
            from: [Key.dailyRecipeSuggestionHour.rawValue: 19]
        ) == .off)
    }

    @Test(arguments: RecipeSuggestionNotificationMode.allCases)
    func migration_keepsAnExistingMode(mode: RecipeSuggestionNotificationMode) {
        let values: [String: Any] = [
            Key.recipeSuggestionNotificationMode.rawValue: mode.rawValue,
            Key.isDailyRecipeSuggestionNotificationOn.rawValue: true,
            Key.lastLaunchedAppVersion.rawValue: "4.0"
        ]
        #expect(RecipeSuggestionNotificationMode.migratedValue(from: values) == mode)
    }

    @Test
    func migration_ignoresRegisteredDefaultsOnNewInstall() throws {
        let domain = "CookleSuggestionMigrationTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }
        defaults.register(defaults: [Key.isDailyRecipeSuggestionNotificationOn.rawValue: false])
        #expect(CooklePreferences.migrateSuggestionNotificationMode(domainName: domain, in: defaults) == .adaptive)
        defaults.set("4.1", forKey: Key.lastLaunchedAppVersion.rawValue)
        let restarted = try #require(UserDefaults(suiteName: domain))
        #expect(CooklePreferences.migrateSuggestionNotificationMode(domainName: domain, in: restarted) == .adaptive)
    }

    @Test(arguments: [true, false])
    func migration_isIdempotentAcrossRestartAndPreservesFixedTime(wasEnabled: Bool) throws {
        let domain = "CookleSuggestionMigrationTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }
        defaults.set(wasEnabled, forKey: Key.isDailyRecipeSuggestionNotificationOn.rawValue)
        defaults.set(19, forKey: Key.dailyRecipeSuggestionHour.rawValue)
        defaults.set(45, forKey: Key.dailyRecipeSuggestionMinute.rawValue)
        let expected: RecipeSuggestionNotificationMode = wasEnabled ? .fixed : .off
        #expect(CooklePreferences.migrateSuggestionNotificationMode(domainName: domain, in: defaults) == expected)
        let first = try JSONSerialization.data(
            withJSONObject: defaults.persistentDomain(forName: domain) ?? [:], options: .sortedKeys
        )
        let restarted = try #require(UserDefaults(suiteName: domain))
        #expect(CooklePreferences.migrateSuggestionNotificationMode(domainName: domain, in: restarted) == expected)
        let after = try JSONSerialization.data(
            withJSONObject: restarted.persistentDomain(forName: domain) ?? [:], options: .sortedKeys
        )
        #expect(first == after)
        #expect(restarted.integer(forKey: Key.dailyRecipeSuggestionHour.rawValue) == 19)
        #expect(restarted.integer(forKey: Key.dailyRecipeSuggestionMinute.rawValue) == 45)
    }
}
