import CookleLibrary
import Foundation
import MHPreferences
import Testing

@testable import Cookle

@Suite(.serialized)
struct CooklePreferenceLifecycleTests {
    private enum TestValues {
        static let dailyRecipeSuggestionHour = 18
    }

    @Test
    func run_keepsCurrentKeys_and_removes_stale_standard_and_shared_keys() async throws {
        let context = try makeLifecycleContext()
        defer {
            restoreDomain(
                context.standardSnapshot,
                named: context.standardDomainName,
                in: context.standardDefaults
            )
            restoreDomain(
                context.sharedSnapshot,
                named: context.sharedDomainName,
                in: context.sharedDefaults
            )
        }

        seedDomains(
            standardDefaults: context.standardDefaults,
            standardDomainName: context.standardDomainName,
            sharedDefaults: context.sharedDefaults,
            sharedDomainName: context.sharedDomainName
        )

        let outcome = await CooklePreferenceLifecycle.run(
            standardDomainName: context.standardDomainName
        )

        let standardDomain = context.standardDefaults.persistentDomain(
            forName: context.standardDomainName
        ) ?? [:]
        let sharedDomain = context.sharedDefaults.persistentDomain(
            forName: context.sharedDomainName
        ) ?? [:]

        assertStandardDomain(
            standardDomain
        )
        assertSharedDomain(
            sharedDomain
        )
        assertCleanupReports(
            outcome.cleanupReports,
            standardDomainName: context.standardDomainName,
            sharedDomainName: context.sharedDomainName
        )
    }
}

private extension CooklePreferenceLifecycleTests {
    struct LifecycleContext {
        let standardDomainName: String
        let standardDefaults: UserDefaults
        let standardSnapshot: [String: Any]
        let sharedDomainName: String
        let sharedDefaults: UserDefaults
        let sharedSnapshot: [String: Any]
    }

    func makeLifecycleContext() throws -> LifecycleContext {
        let standardDomainName = "CooklePreferenceLifecycleTests.standard.\(UUID().uuidString)"
        let standardDefaults = UserDefaults.standard
        let sharedDefaults = try #require(
            UserDefaults(
                suiteName: UserDefaults.appGroupIdentifier
            )
        )
        let sharedDomainName = UserDefaults.appGroupIdentifier

        return .init(
            standardDomainName: standardDomainName,
            standardDefaults: standardDefaults,
            standardSnapshot: snapshotDomain(
                named: standardDomainName,
                from: standardDefaults
            ),
            sharedDomainName: sharedDomainName,
            sharedDefaults: sharedDefaults,
            sharedSnapshot: snapshotDomain(
                named: sharedDomainName,
                from: sharedDefaults
            )
        )
    }

    func seedDomains(
        standardDefaults: UserDefaults,
        standardDomainName: String,
        sharedDefaults: UserDefaults,
        sharedDomainName: String
    ) {
        standardDefaults.setPersistentDomain(
            [
                BoolPreferenceKey.isDebugOn.rawValue: true,
                IntPreferenceKey.dailyRecipeSuggestionHour.rawValue:
                    TestValues.dailyRecipeSuggestionHour,
                StringPreferenceKey.lastLaunchedAppVersion.rawValue: "3.0",
                DiaryFormSnapshot.preferenceDescriptor.storageKey: Data("diary".utf8),
                RecipeFormSnapshot.preferenceDescriptor.storageKey: Data("recipe".utf8),
                CookleAppLogging.snapshotStorageDescriptors.current.storageKey: Data("current".utf8),
                CookleAppLogging.snapshotStorageDescriptors.previous.storageKey: Data("previous".utf8),
                StringPreferenceKey.lastOpenedRecipeID.rawValue: "legacy-standard",
                "cookle.standard.stale": "remove"
            ],
            forName: standardDomainName
        )
        sharedDefaults.setPersistentDomain(
            [
                StringPreferenceKey.lastOpenedRecipeID.rawValue: "current-shared",
                BoolPreferenceKey.isDebugOn.rawValue: true,
                "cookle.shared.stale": "remove"
            ],
            forName: sharedDomainName
        )
    }

    func assertStandardDomain(
        _ standardDomain: [String: Any]
    ) {
        #expect(standardDomain[BoolPreferenceKey.isDebugOn.rawValue] as? Bool == true)
        #expect(
            standardDomain[IntPreferenceKey.dailyRecipeSuggestionHour.rawValue] as? Int
                == TestValues.dailyRecipeSuggestionHour
        )
        #expect(
            standardDomain[StringPreferenceKey.lastLaunchedAppVersion.rawValue] as? String == "3.0"
        )
        #expect(
            standardDomain[DiaryFormSnapshot.preferenceDescriptor.storageKey] as? Data
                == Data("diary".utf8)
        )
        #expect(
            standardDomain[RecipeFormSnapshot.preferenceDescriptor.storageKey] as? Data
                == Data("recipe".utf8)
        )
        #expect(
            standardDomain[CookleAppLogging.snapshotStorageDescriptors.current.storageKey] as? Data
                == Data("current".utf8)
        )
        #expect(
            standardDomain[CookleAppLogging.snapshotStorageDescriptors.previous.storageKey] as? Data
                == Data("previous".utf8)
        )
        #expect(standardDomain[StringPreferenceKey.lastOpenedRecipeID.rawValue] == nil)
        #expect(standardDomain["cookle.standard.stale"] == nil)
    }

    func assertSharedDomain(
        _ sharedDomain: [String: Any]
    ) {
        #expect(
            sharedDomain[StringPreferenceKey.lastOpenedRecipeID.rawValue] as? String
                == "current-shared"
        )
        #expect(sharedDomain[BoolPreferenceKey.isDebugOn.rawValue] == nil)
        #expect(sharedDomain["cookle.shared.stale"] == nil)
    }

    func assertCleanupReports(
        _ reports: [MHPreferenceDomainCleanupReport],
        standardDomainName: String,
        sharedDomainName: String
    ) {
        #expect(
            reports.contains { report in
                report.domainName == standardDomainName
                    && report.report.removedStorageKeys == [
                        "cookle.standard.stale",
                        StringPreferenceKey.lastOpenedRecipeID.rawValue
                    ]
            }
        )
        #expect(
            reports.contains { report in
                report.domainName == sharedDomainName
                    && report.report.removedStorageKeys == [
                        "cookle.shared.stale",
                        BoolPreferenceKey.isDebugOn.rawValue
                    ]
            }
        )
    }

    func snapshotDomain(
        named domainName: String,
        from userDefaults: UserDefaults
    ) -> [String: Any] {
        userDefaults.persistentDomain(
            forName: domainName
        ) ?? [:]
    }

    func restoreDomain(
        _ snapshot: [String: Any],
        named domainName: String,
        in userDefaults: UserDefaults
    ) {
        if snapshot.isEmpty == false {
            userDefaults.setPersistentDomain(
                snapshot,
                forName: domainName
            )
        } else {
            userDefaults.removePersistentDomain(
                forName: domainName
            )
        }
    }
}
