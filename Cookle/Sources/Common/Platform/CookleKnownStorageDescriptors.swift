import CookleLibrary
import MHPlatform

enum CookleKnownStorageDescriptors {
    nonisolated static let preferenceLifecycleState = MHPreferenceMigrationStateDescriptor(
        storageKey: CookleUserDefaultsKeys.Standard.preferenceMigrationState.rawValue,
        defaultSelection: .standard
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

    nonisolated static var all: [any MHStorageDescriptorProtocol] {
        preferenceLifecycleDescriptors
            + [
                preferenceLifecycleState
            ]
    }
}
