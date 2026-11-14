@testable import CookleLibrary
import Foundation
import MHPlatformCore
import Testing

struct ICloudSyncOperationsTests {
    @Test(arguments: [false, true])
    func subscriptionLapseAndRenewalPreserveTheSavedChoice(isICloudOn: Bool) throws {
        try withStore { store, reopenedStore in
            store.set(isICloudOn, for: \.isICloudOn)
            ICloudSyncOperations.updateSubscriptionAccess(.active, store: store)
            let activeStore = try reopenedStore()
            #expect(ICloudSyncOperations.isEnabledAtNextLaunch(store: activeStore) == isICloudOn)

            ICloudSyncOperations.updateSubscriptionAccess(.inactive, store: store)
            let inactiveStore = try reopenedStore()
            #expect(!ICloudSyncOperations.isEnabledAtNextLaunch(store: inactiveStore))
            #expect(store.bool(for: \.isICloudOn) == isICloudOn)

            ICloudSyncOperations.updateSubscriptionAccess(.active, store: store)
            let renewedStore = try reopenedStore()
            #expect(ICloudSyncOperations.isEnabledAtNextLaunch(store: renewedStore) == isICloudOn)
            #expect(store.bool(for: \.isICloudOn) == isICloudOn)
        }
    }

    @Test(arguments: [false, true], [false, true])
    func unresolvedEntitlementKeepsBothPreferences(isActive: Bool, isICloudOn: Bool) throws {
        try withStore { store, reopenedStore in
            store.set(isActive, for: \.isSubscribeOn)
            store.set(isICloudOn, for: \.isICloudOn)

            ICloudSyncOperations.updateSubscriptionAccess(.unknown, store: store)

            #expect(store.bool(for: \.isSubscribeOn) == isActive)
            #expect(store.bool(for: \.isICloudOn) == isICloudOn)
            let unresolvedStore = try reopenedStore()
            #expect(ICloudSyncOperations.isEnabledAtNextLaunch(store: unresolvedStore) == (isActive && isICloudOn))
        }
    }

    @Test
    func firstPurchaseDoesNotOptIntoSync() throws {
        try withStore { store, reopenedStore in
            ICloudSyncOperations.updateSubscriptionAccess(.active, store: store)

            #expect(store.bool(for: \.isSubscribeOn))
            #expect(!store.bool(for: \.isICloudOn))
            let purchasedStore = try reopenedStore()
            #expect(!ICloudSyncOperations.isEnabledAtNextLaunch(store: purchasedStore))
        }
    }

    @Test
    func explicitOffDuringALapseSurvivesRenewal() throws {
        try withStore { store, reopenedStore in
            store.set(true, for: \.isICloudOn)
            ICloudSyncOperations.updateSubscriptionAccess(.inactive, store: store)
            store.set(false, for: \.isICloudOn)

            ICloudSyncOperations.updateSubscriptionAccess(.active, store: store)

            #expect(!store.bool(for: \.isICloudOn))
            let renewedStore = try reopenedStore()
            #expect(!ICloudSyncOperations.isEnabledAtNextLaunch(store: renewedStore))
        }
    }

    @Test(arguments: [false, true])
    func reversingAPendingChoiceRestoresTheNextLaunchSetting(initialChoice: Bool) throws {
        try withStore { store, reopenedStore in
            ICloudSyncOperations.updateSubscriptionAccess(.active, store: store)
            store.set(initialChoice, for: \.isICloudOn)
            let initialStore = try reopenedStore()
            #expect(ICloudSyncOperations.isEnabledAtNextLaunch(store: initialStore) == initialChoice)

            store.set(!initialChoice, for: \.isICloudOn)
            let pendingStore = try reopenedStore()
            #expect(ICloudSyncOperations.isEnabledAtNextLaunch(store: pendingStore) != initialChoice)

            store.set(initialChoice, for: \.isICloudOn)
            let cancelledStore = try reopenedStore()
            #expect(ICloudSyncOperations.isEnabledAtNextLaunch(store: cancelledStore) == initialChoice)
        }
    }
}

private extension ICloudSyncOperationsTests {
    func withStore(_ operation: (MHPreferenceStore, () throws -> MHPreferenceStore) throws -> Void) throws {
        let suiteName = "ICloudSyncOperationsTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        try operation(.init(userDefaults: defaults)) {
            .init(userDefaults: try #require(UserDefaults(suiteName: suiteName)))
        }
    }
}
