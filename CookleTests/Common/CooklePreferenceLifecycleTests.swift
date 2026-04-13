import CookleLibrary
import Foundation
import MHPreferences
import Testing

@testable import Cookle

@Suite(.serialized)
struct CooklePreferenceLifecycleTests {
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

    enum TestValues {
        static let dailyRecipeSuggestionHour = 18
        static let oldDiarySnapshotStorageKey = "cookle.formSnapshot.diary"
        static let oldRecipeSnapshotStorageKey = "cookle.formSnapshot.recipe"
        static let oldLoggingCurrentStorageKey = "cookle.logging.last-session.current-session"
        static let oldLoggingPreviousStorageKey = "cookle.logging.last-session.previous-session"
        static let oldPendingIntentDeepLinkStorageKey = "pendingCookleIntentDeepLinkURL"
        static let oldLifecycleStateStorageKey = "cookle.preferences.lifecycle-state"
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
        let descriptors = MHPreferenceDescriptors()
        standardDefaults.setPersistentDomain(
            [
                descriptors.isDebugOn.storageKey: true,
                descriptors.dailyRecipeSuggestionHour.storageKey:
                    TestValues.dailyRecipeSuggestionHour,
                descriptors.lastLaunchedAppVersion.storageKey: "3.0",
                DiaryFormSnapshot.preferenceDescriptor.storageKey: Data("diary".utf8),
                RecipeFormSnapshot.preferenceDescriptor.storageKey: Data("recipe".utf8),
                CookleAppLogging.snapshotStorageDescriptors.current.storageKey: Data("current".utf8),
                CookleAppLogging.snapshotStorageDescriptors.previous.storageKey: Data("previous".utf8),
                CookleKnownStorageDescriptors.preferenceLifecycleState.storageKey: Data("state".utf8),
                descriptors.lastOpenedRecipeID.storageKey: "legacy-standard",
                TestValues.oldDiarySnapshotStorageKey: Data("old-diary".utf8),
                TestValues.oldRecipeSnapshotStorageKey: Data("old-recipe".utf8),
                TestValues.oldLoggingCurrentStorageKey: Data("old-current".utf8),
                TestValues.oldLoggingPreviousStorageKey: Data("old-previous".utf8),
                TestValues.oldLifecycleStateStorageKey: Data("old-state".utf8),
                "cookle.standard.stale": "remove"
            ],
            forName: standardDomainName
        )
        sharedDefaults.setPersistentDomain(
            [
                descriptors.lastOpenedRecipeID.storageKey: "current-shared",
                descriptors.pendingIntentDeepLinkURL.storageKey: "current-deep-link",
                TestValues.oldPendingIntentDeepLinkStorageKey: "legacy-deep-link",
                descriptors.isDebugOn.storageKey: true,
                "cookle.shared.stale": "remove"
            ],
            forName: sharedDomainName
        )
    }

    func assertStandardDomain(
        _ standardDomain: [String: Any]
    ) {
        let descriptors = MHPreferenceDescriptors()
        #expect(standardDomain[descriptors.isDebugOn.storageKey] as? Bool == true)
        #expect(
            standardDomain[descriptors.dailyRecipeSuggestionHour.storageKey] as? Int
                == TestValues.dailyRecipeSuggestionHour
        )
        #expect(
            standardDomain[descriptors.lastLaunchedAppVersion.storageKey] as? String == "3.0"
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
        #expect(
            standardDomain[CookleKnownStorageDescriptors.preferenceLifecycleState.storageKey] as? Data
                == Data("state".utf8)
        )
        #expect(standardDomain[descriptors.lastOpenedRecipeID.storageKey] == nil)
        #expect(standardDomain[TestValues.oldDiarySnapshotStorageKey] == nil)
        #expect(standardDomain[TestValues.oldRecipeSnapshotStorageKey] == nil)
        #expect(standardDomain[TestValues.oldLoggingCurrentStorageKey] == nil)
        #expect(standardDomain[TestValues.oldLoggingPreviousStorageKey] == nil)
        #expect(standardDomain[TestValues.oldLifecycleStateStorageKey] == nil)
        #expect(standardDomain["cookle.standard.stale"] == nil)
    }

    func assertSharedDomain(
        _ sharedDomain: [String: Any]
    ) {
        let descriptors = MHPreferenceDescriptors()
        #expect(
            sharedDomain[descriptors.lastOpenedRecipeID.storageKey] as? String
                == "current-shared"
        )
        #expect(sharedDomain[descriptors.isDebugOn.storageKey] == nil)
        #expect(sharedDomain[TestValues.oldPendingIntentDeepLinkStorageKey] == nil)
        #expect(sharedDomain["cookle.shared.stale"] == nil)
    }

    func assertCleanupReports(
        _ reports: [MHPreferenceDomainCleanupReport],
        standardDomainName: String,
        sharedDomainName: String
    ) {
        let descriptors = MHPreferenceDescriptors()
        #expect(
            reports.contains { report in
                report.domainName == standardDomainName
                    && Set(report.report.removedStorageKeys) == Set([
                        TestValues.oldDiarySnapshotStorageKey,
                        TestValues.oldLoggingCurrentStorageKey,
                        TestValues.oldLoggingPreviousStorageKey,
                        TestValues.oldLifecycleStateStorageKey,
                        TestValues.oldRecipeSnapshotStorageKey,
                        "cookle.standard.stale",
                        descriptors.lastOpenedRecipeID.storageKey
                    ])
            }
        )
        #expect(
            reports.contains { report in
                report.domainName == sharedDomainName
                    && Set(report.report.removedStorageKeys) == Set([
                        "cookle.shared.stale",
                        descriptors.isDebugOn.storageKey,
                        TestValues.oldPendingIntentDeepLinkStorageKey
                    ])
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
