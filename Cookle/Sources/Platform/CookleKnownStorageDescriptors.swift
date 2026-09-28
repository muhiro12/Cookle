import CookleLibrary
import MHPlatform

enum CookleKnownStorageDescriptors {
    nonisolated static let preferenceLifecycleState = MHPreferenceMigrationStateDescriptor(
        storageKey: CookleUserDefaultsKeys.Standard.preferenceMigrationState.rawValue,
        defaultSelection: .standard
    )

    /// The complete cleanup allowlist, including external keys, and its
    /// migration state.
    nonisolated static let preferenceRegistry = MHPreferenceRegistry(
        descriptors: preferenceLifecycleDescriptors,
        migrationStateDescriptor: preferenceLifecycleState
    )

    /// Exact keys that Apple frameworks write into the standard app domain.
    /// Cookle does not own them, so cleanup must keep them.
    nonisolated static let externalStandardDomainKeys: [MHRawStorageDescriptor] = [
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
    }
}
