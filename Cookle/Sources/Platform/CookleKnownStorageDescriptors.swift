import CookleLibrary
import MHPlatform

enum CookleKnownStorageDescriptors {
    nonisolated static let preferenceLifecycleState = MHPreferenceMigrationStateDescriptor(
        storageKey: CookleUserDefaultsKeys.Standard.preferenceMigrationState.rawValue,
        defaultSelection: .standard
    )

    /// The complete app-owned preference allowlist and its migration state.
    nonisolated static let preferenceRegistry = MHPreferenceRegistry(
        descriptors: preferenceLifecycleDescriptors,
        migrationStateDescriptor: preferenceLifecycleState
    )

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
    }
}
