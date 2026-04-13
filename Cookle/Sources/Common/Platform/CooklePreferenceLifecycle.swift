import CookleLibrary
import Foundation
import MHPlatform

enum CooklePreferenceLifecycle {
    static func run(
        standardDomainName: String? = Bundle.main.bundleIdentifier
    ) async -> MHPreferenceLifecycleOutcome {
        await MHPreferenceLifecycleService.run(
            descriptors: CookleKnownStorageDescriptors.preferenceLifecycleDescriptors,
            migrationStateDescriptor: CookleKnownStorageDescriptors.preferenceLifecycleState,
            standardDomainName: standardDomainName
        )
    }
}
