@testable import CookleLibrary
import Foundation
import MHPlatformCore
import Testing

struct ICloudSyncOperationsTests {
    @Test(arguments: [false, true])
    func subscriptionLapseAndRenewalPreserveTheSavedChoice(isICloudOn: Bool) throws {
        try withStore { store in
            store.set(isICloudOn, for: \.isICloudOn)
            ICloudSyncOperations.updateSubscriptionAccess(.active, store: store)
            #expect(setting(store: store) == isICloudOn)

            ICloudSyncOperations.updateSubscriptionAccess(.inactive, store: store)
            #expect(!setting(store: store, isSyncAlreadyRequested: true, isEditing: true))
            #expect(store.bool(for: \.isICloudOn) == isICloudOn)

            ICloudSyncOperations.updateSubscriptionAccess(.active, store: store)
            #expect(setting(store: store) == isICloudOn)
            #expect(store.bool(for: \.isICloudOn) == isICloudOn)
        }
    }

    @Test(arguments: [false, true], [false, true])
    func unresolvedEntitlementKeepsBothPreferences(isActive: Bool, isICloudOn: Bool) throws {
        try withStore { store in
            store.set(isActive, for: \.isSubscribeOn)
            store.set(isICloudOn, for: \.isICloudOn)

            ICloudSyncOperations.updateSubscriptionAccess(.unknown, store: store)

            #expect(store.bool(for: \.isSubscribeOn) == isActive)
            #expect(store.bool(for: \.isICloudOn) == isICloudOn)
        }
    }

    @Test
    func renewalWaitsUntilEditingFinishes() throws {
        try withStore { store in
            store.set(true, for: \.isICloudOn)
            ICloudSyncOperations.updateSubscriptionAccess(.active, store: store)

            #expect(!setting(store: store, isEditing: true))
            #expect(store.bool(for: \.isICloudOn))
            #expect(setting(store: store))
            #expect(setting(store: store, isSyncAlreadyRequested: true, isEditing: true))
        }
    }

    @Test
    func turningSyncOffTakesEffectDuringAnEdit() throws {
        try withStore { store in
            ICloudSyncOperations.updateSubscriptionAccess(.active, store: store)
            store.set(true, for: \.isICloudOn)
            #expect(setting(store: store))

            store.set(false, for: \.isICloudOn)

            #expect(!setting(store: store, isSyncAlreadyRequested: true, isEditing: true))
            #expect(!setting(store: store))
        }
    }
}

private extension ICloudSyncOperationsTests {
    func setting(
        store: MHPreferenceStore,
        isSyncAlreadyRequested: Bool = false,
        isEditing: Bool = false
    ) -> Bool {
        ICloudSyncOperations.settingToApply(
            isSyncAlreadyRequested: isSyncAlreadyRequested,
            isEditing: isEditing,
            store: store
        )
    }

    func withStore(_ operation: (MHPreferenceStore) throws -> Void) throws {
        let suiteName = "ICloudSyncOperationsTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        try operation(.init(userDefaults: defaults))
    }
}
