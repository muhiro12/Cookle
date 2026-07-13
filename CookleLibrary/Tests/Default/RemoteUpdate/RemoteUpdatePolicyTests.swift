import CookleLibrary
import Foundation
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
