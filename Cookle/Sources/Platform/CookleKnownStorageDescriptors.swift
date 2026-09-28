import CookleLibrary
import MHAppRuntimeAds
import MHPlatform

enum CookleKnownStorageDescriptors {
    nonisolated static let preferenceLifecycleState = MHPreferenceMigrationStateDescriptor(
        storageKey: CookleUserDefaultsKeys.Standard.preferenceMigrationState.rawValue,
        defaultSelection: .standard
    )

    /// The complete cleanup allowlist, including external keys, and its
    /// migration state. Built on each access because the consent SDK's keys
    /// depend on what it has stored so far.
    nonisolated static var preferenceRegistry: MHPreferenceRegistry {
        .init(
            descriptors: preferenceLifecycleDescriptors,
            migrationStateDescriptor: preferenceLifecycleState
        )
    }

    /// Exact keys that Apple frameworks write into the standard app domain.
    /// Cookle does not own them, so cleanup must keep them.
    nonisolated static let externalStandardDomainKeys: [MHRawStorageDescriptor] = [
        "SKSubscriptionStatusUpdatesLastChecked",
        "SKTransactionUpdatesLastChecked",
        "com.apple.UIKit.UISplitViewController.Root"
    ]
    .map { storageKey in
        .init(
            storageKey: storageKey,
            defaultSelection: .standard
        )
    }

    nonisolated static var primitivePreferences: [any MHStorageDescriptorProtocol] {
        CooklePreferenceCatalog.primitiveDescriptors
    }

    nonisolated static var preferenceLifecycleDescriptors: [any MHStorageDescriptorProtocol] {
        primitivePreferences
            + [
                DiaryFormSnapshot.preferenceDescriptor,
                RecipeFormSnapshot.preferenceDescriptor,
                CookleAppLogging.snapshotStorageDescriptors.current,
                CookleAppLogging.snapshotStorageDescriptors.previous
            ]
            + externalStandardDomainKeys
            + MHAdsConsentStorage.currentDescriptors()
    }
}
