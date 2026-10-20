import CookleLibrary
import Foundation
import MHPlatform
import Observation

@MainActor
@Observable
final class RemoteConfigurationService {
    let updates: RemoteUpdateOperations
    private let logger: MHLogger

    var isUpdateRequired: Bool {
        updates.decision == .updateRequired
    }

    init(updates: RemoteUpdateOperations, logger: MHLogger) {
        self.updates = updates
        self.logger = logger
    }

    func load() async {
        do {
            guard let preparation = try await updates.prepare() else {
                return
            }
            let evaluation = preparation.evaluation
            logger.info(
                "remote update evaluated",
                metadata: [
                    "reason": evaluation.reason.rawValue,
                    "revision": evaluation.revision.map(String.init) ?? "none",
                    "policyFreshness": evaluation.policyFreshness.rawValue,
                    "publicationFreshness": evaluation.publicationFreshness.rawValue
                ]
            )
            for error in [preparation.restorationError, preparation.refreshError].compactMap(\.self) {
                logger.warning(
                    "remote update evidence could not be refreshed",
                    metadata: ["errorType": String(reflecting: type(of: error))]
                )
            }
        } catch is CancellationError {
            return
        } catch {
            logger.error(
                "remote update preparation failed",
                metadata: ["errorType": String(reflecting: type(of: error))]
            )
        }
    }
}
