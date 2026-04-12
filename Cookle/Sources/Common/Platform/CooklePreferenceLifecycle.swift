import CookleLibrary
import Foundation
import MHPlatform

enum CooklePreferenceLifecycle {
    private static let migrationStateDescriptor =
        CookleInternalPreferenceKey.preferenceLifecycleState.migrationStateDescriptor

    static func run(
        standardDomainName: String? = Bundle.main.bundleIdentifier
    ) async -> MHPreferenceLifecycleOutcome {
        await MHPreferenceLifecycleService.run(
            descriptors: descriptors,
            migrationStateDescriptor: migrationStateDescriptor,
            standardDomainName: standardDomainName
        )
    }
}

private extension CooklePreferenceLifecycle {
    static var descriptors: [any MHStorageDescriptorProtocol] {
        boolDescriptors
            + intDescriptors
            + stringDescriptors
            + snapshotDescriptors
            + loggingDescriptors
    }

    static var boolDescriptors: [any MHStorageDescriptorProtocol] {
        BoolPreferenceKey.allCases.map(\.preferenceDescriptor)
    }

    static var intDescriptors: [any MHStorageDescriptorProtocol] {
        IntPreferenceKey.allCases.map { key in
            key.preferenceDescriptor(default: .zero)
        }
    }

    static var stringDescriptors: [any MHStorageDescriptorProtocol] {
        StringPreferenceKey.allCases.map(\.preferenceDescriptor)
    }

    static var snapshotDescriptors: [any MHStorageDescriptorProtocol] {
        [
            DiaryFormSnapshot.preferenceDescriptor,
            RecipeFormSnapshot.preferenceDescriptor
        ]
    }

    static var loggingDescriptors: [any MHStorageDescriptorProtocol] {
        [
            CookleAppLogging.snapshotStorageDescriptors.current,
            CookleAppLogging.snapshotStorageDescriptors.previous
        ]
    }
}
