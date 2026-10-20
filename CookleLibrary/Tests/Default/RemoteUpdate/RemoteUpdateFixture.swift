import Foundation
import MHPlatformCore
import Synchronization

final class RemoteUpdateFixture: Sendable {
    private enum Timing {
        static let start: TimeInterval = 1_000
        static let policyLifetime: TimeInterval = 3_600
        static let publicationLifetime: TimeInterval = 600
    }

    let clock = Mutex(Date(timeIntervalSinceReferenceDate: Timing.start))
    let failsRefresh = Mutex(false)
    let fetchCount = Mutex(0)
    let schedule: MHRemoteUpdateSchedule

    init(configuration: String) throws {
        schedule = try MHRemoteUpdateSchedule.decode(Data(configuration.utf8))
    }

    init(effectiveAt: TimeInterval = 1_000) throws {
        guard let minimum = MHAppVersion("4.0") else {
            preconditionFailure("Invalid test version.")
        }
        schedule = try .init(
            bundleIdentifier: "com.muhiro12.Cookle",
            revision: 1,
            requirement: nil,
            scheduledRequirements: [
                .init(minimumVersion: minimum, effectiveAt: Date(timeIntervalSinceReferenceDate: effectiveAt))
            ]
        )
    }

    func controller(store: MHRemoteUpdateStore? = nil) throws -> MHRemoteUpdateController {
        try .init(
            bundleIdentifier: "com.muhiro12.Cookle",
            storefront: "jp",
            policyLifetime: Timing.policyLifetime,
            publicationLifetime: Timing.publicationLifetime,
            store: store,
            currentVersion: { "3.9" },
            now: { self.clock.withLock { $0 } },
            fetchSchedule: {
                self.fetchCount.withLock { $0 += 1 }
                if self.failsRefresh.withLock({ $0 }) {
                    throw URLError(.notConnectedToInternet)
                }
                return .init(value: self.schedule, fetchedAt: self.clock.withLock { $0 })
            },
            publicVersion: { MHAppVersion("4.0") }
        )
    }
}
