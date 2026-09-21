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

    /// Runs the preference lifecycle without an `await`, for callers that must
    /// finish before any preference is read.
    ///
    /// `CookleApp.init()` needs this: App Intents can launch the app with no
    /// scene, so registering their dependencies cannot wait for a `Task`, and
    /// the registration reads `isICloudOn` to decide how to open the store.
    nonisolated static func runSynchronously(
        standardDomainName: String? = Bundle.main.bundleIdentifier
    ) -> MHPreferenceLifecycleOutcome {
        let outcomeBox = OutcomeBox()

        Task.detached(priority: .userInitiated) {
            let outcome = await MHPreferenceLifecycleService.run(
                descriptors: CookleKnownStorageDescriptors.preferenceLifecycleDescriptors,
                migrationStateDescriptor: CookleKnownStorageDescriptors.preferenceLifecycleState,
                standardDomainName: standardDomainName
            )
            outcomeBox.store(outcome)
        }

        return outcomeBox.wait()
    }
}

private extension CooklePreferenceLifecycle {
    nonisolated final class OutcomeBox: @unchecked Sendable {
        private let lock = NSLock()
        private let semaphore = DispatchSemaphore(value: .zero)
        private var outcome: MHPreferenceLifecycleOutcome?

        func store(
            _ outcome: MHPreferenceLifecycleOutcome
        ) {
            lock.lock()
            self.outcome = outcome
            lock.unlock()
            semaphore.signal()
        }

        func wait() -> MHPreferenceLifecycleOutcome {
            semaphore.wait()

            lock.lock()
            defer {
                lock.unlock()
            }

            guard let outcome else {
                preconditionFailure("Preference lifecycle did not produce an outcome.")
            }

            return outcome
        }
    }
}
