import CookleLibrary
import Foundation
import MHPlatformCore
import Synchronization
import Testing

struct RemoteUpdatePolicyTests {
    private let activatedAt = Date(timeIntervalSinceReferenceDate: 1_000)

    @Test
    func requiresUpdateOnlyForOlderInstalledVersionWithinActiveWindow() throws {
        let policy = try #require(
            makePolicy(
                minimumVersion: "3.9",
                duration: 60 * 60
            )
        )
        let currentVersion = try #require(AppVersion("3.8"))
        let publicVersion = try #require(AppVersion("3.9.0"))

        #expect(
            policy.isUpdateRequired(
                currentVersion: currentVersion,
                publicVersion: publicVersion,
                now: activatedAt
            )
        )
        #expect(
            policy.isUpdateRequired(
                currentVersion: currentVersion,
                publicVersion: publicVersion,
                now: policy.expiresAt
            )
        )
    }

    @Test
    func doesNotRequireUpdateOutsideActivationWindow() throws {
        let policy = try #require(makePolicy())
        let currentVersion = try #require(AppVersion("3.8"))
        let publicVersion = try #require(AppVersion("3.9"))

        #expect(
            policy.isUpdateRequired(
                currentVersion: currentVersion,
                publicVersion: publicVersion,
                now: activatedAt.addingTimeInterval(-1)
            ) == false
        )
        #expect(
            policy.isUpdateRequired(
                currentVersion: currentVersion,
                publicVersion: publicVersion,
                now: policy.expiresAt.addingTimeInterval(1)
            ) == false
        )
    }

    @Test
    func doesNotRequireUpdateWhenInstalledVersionMeetsMinimum() throws {
        let policy = try #require(makePolicy(minimumVersion: "3.9"))
        let publicVersion = try #require(AppVersion("4"))

        for currentValue in ["3.9", "3.9.0", "4"] {
            let currentVersion = try #require(AppVersion(currentValue))
            #expect(
                policy.isUpdateRequired(
                    currentVersion: currentVersion,
                    publicVersion: publicVersion,
                    now: activatedAt
                ) == false
            )
        }
    }

    @Test
    func doesNotRequireUpdateToVersionThatIsNotPublic() throws {
        let policy = try #require(makePolicy(minimumVersion: "4"))
        let currentVersion = try #require(AppVersion("3.9"))
        let publicVersion = try #require(AppVersion("3.9.1"))

        #expect(
            policy.isUpdateRequired(
                currentVersion: currentVersion,
                publicVersion: publicVersion,
                now: activatedAt
            ) == false
        )
    }

    @Test
    func acceptsMaximumActivationDuration() throws {
        let policy = try #require(
            makePolicy(
                duration: RemoteUpdatePolicy.maximumActivationDuration
            )
        )

        #expect(
            policy.expiresAt.timeIntervalSince(policy.activatedAt)
                == RemoteUpdatePolicy.maximumActivationDuration
        )
    }

    @Test
    func rejectsNonPositiveAndOversizedActivationWindows() {
        #expect(makePolicy(duration: -1) == nil)
        #expect(makePolicy(duration: 0) == nil)
        #expect(
            makePolicy(
                duration: RemoteUpdatePolicy.maximumActivationDuration + 1
            ) == nil
        )
    }

    @Test
    func evaluatesActivePolicyWithSharedPublicationLookup() async throws {
        let policy = try #require(makePolicy())
        let evaluationDate = activatedAt
        let evaluator = MHRemoteUpdateEvaluator(
            currentVersion: {
                "3.8"
            },
            now: {
                evaluationDate
            },
            publicVersion: {
                AppVersion("3.9")
            }
        )

        #expect(try await evaluator.evaluate(policy.updatePolicy) == .updateRequired)
    }

    @Test
    func skipsPublicationLookupWhenNoUpdateApplies() async throws {
        let policy = try #require(makePolicy())
        let activeDate = activatedAt
        let inactiveDate = policy.expiresAt.addingTimeInterval(1)

        for (version, date) in [("3.9", activeDate), ("3.8", inactiveDate)] {
            let evaluator = MHRemoteUpdateEvaluator(
                currentVersion: {
                    version
                },
                now: {
                    date
                },
                publicVersion: {
                    throw URLError(.notConnectedToInternet)
                }
            )

            #expect(try await evaluator.evaluate(policy.updatePolicy) == .notRequired)
        }
    }

    @Test
    func distinguishesUnpublishedMinimumFromPermissionToContinue() async throws {
        let policy = try #require(makePolicy())
        let evaluationDate = activatedAt
        let evaluator = MHRemoteUpdateEvaluator(
            currentVersion: {
                "3.8"
            },
            now: {
                evaluationDate
            },
            publicVersion: {
                AppVersion("3.8.1")
            }
        )

        #expect(try await evaluator.evaluate(policy.updatePolicy) == .unavailable)
    }

    @Test
    func reevaluatesExpiryAfterPublicationLookup() async throws {
        let policy = try #require(makePolicy())
        let clock = Mutex(activatedAt)
        let expiredDate = policy.expiresAt.addingTimeInterval(1)
        let evaluator = MHRemoteUpdateEvaluator(
            currentVersion: {
                "3.8"
            },
            now: {
                clock.withLock { date in
                    date
                }
            },
            publicVersion: {
                clock.withLock { date in
                    date = expiredDate
                }
                return AppVersion("3.9")
            }
        )

        #expect(try await evaluator.evaluate(policy.updatePolicy) == .notRequired)
    }

    @Test
    func propagatesPublicationFailureInsteadOfGrantingPermission() async throws {
        let policy = try #require(makePolicy())
        let evaluationDate = activatedAt
        let evaluator = MHRemoteUpdateEvaluator(
            currentVersion: {
                "3.8"
            },
            now: {
                evaluationDate
            },
            publicVersion: {
                throw URLError(.notConnectedToInternet)
            }
        )

        await #expect(throws: URLError(.notConnectedToInternet)) {
            try await evaluator.evaluate(policy.updatePolicy)
        }
    }

    @Test
    func propagatesCancellationInsteadOfApplyingAnUpdateDecision() async throws {
        let policy = try #require(makePolicy())
        let evaluationDate = activatedAt
        let evaluator = MHRemoteUpdateEvaluator(
            currentVersion: {
                "3.8"
            },
            now: {
                evaluationDate
            },
            publicVersion: {
                throw URLError(.cancelled)
            }
        )

        await #expect(throws: CancellationError.self) {
            try await evaluator.evaluate(policy.updatePolicy)
        }
    }

    private func makePolicy(
        minimumVersion: String = "3.9",
        duration: TimeInterval = 60 * 60
    ) -> RemoteUpdatePolicy? {
        guard let parsedMinimumVersion = AppVersion(minimumVersion) else {
            return nil
        }
        return .init(
            minimumVersion: parsedMinimumVersion,
            activatedAt: activatedAt,
            expiresAt: activatedAt.addingTimeInterval(duration)
        )
    }
}
