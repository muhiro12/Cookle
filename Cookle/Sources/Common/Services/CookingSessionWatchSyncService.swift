import Foundation
import WatchConnectivity

@MainActor
final class CookingSessionWatchSyncService: NSObject, WCSessionDelegate {
    private let cookingSessionStore: CookingSessionStore
    private let session: WCSession?

    init(
        cookingSessionStore: CookingSessionStore,
        session: WCSession? = WCSession.isSupported() ? .default : nil
    ) {
        self.cookingSessionStore = cookingSessionStore
        self.session = session
        super.init()
        self.session?.delegate = self
        cookingSessionStore.setSnapshotChangeHandler { [weak self] snapshot in
            self?.sendSnapshot(
                snapshot
            )
        }
        applyApplicationContext(
            session?.receivedApplicationContext ?? [:]
        )
        self.session?.activate()
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith _: WCSessionActivationState,
        error _: (any Error)?
    ) {
        let encodedSnapshot = session.receivedApplicationContext[
            "activeCookingSessionSnapshot"
        ] as? String
        Task { @MainActor in
            self.applyEncodedSnapshot(
                encodedSnapshot
            )
            self.sendSnapshot(
                self.cookingSessionStore.snapshot
            )
        }
    }

    nonisolated func sessionDidBecomeInactive(
        _: WCSession
    ) {
        // No-op. The iOS app reactivates in `sessionDidDeactivate`.
    }

    nonisolated func sessionDidDeactivate(
        _ session: WCSession
    ) {
        session.activate()
    }

    nonisolated func session(
        _: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        let encodedSnapshot = applicationContext[
            "activeCookingSessionSnapshot"
        ] as? String
        Task { @MainActor in
            self.applyEncodedSnapshot(
                encodedSnapshot
            )
        }
    }

    func applyApplicationContext(
        _ applicationContext: [String: Any]
    ) {
        let encodedSnapshot = applicationContext[
            "activeCookingSessionSnapshot"
        ] as? String
        applyEncodedSnapshot(
            encodedSnapshot
        )
    }

    func applyEncodedSnapshot(
        _ encodedSnapshot: String?
    ) {
        guard let encodedSnapshot,
              encodedSnapshot.isEmpty == false,
              let snapshot = CookingSessionSnapshot.decoded(
                from: encodedSnapshot
              ) else {
            return
        }

        cookingSessionStore.applyIncomingSnapshot(
            snapshot
        )
    }

    func sendSnapshot(
        _ snapshot: CookingSessionSnapshot?
    ) {
        guard let session,
              canSendSnapshot(
                with: session
              ) else {
            return
        }

        do {
            try session.updateApplicationContext(
                [
                    "activeCookingSessionSnapshot":
                        snapshot?.encodedString() ?? ""
                ]
            )
        } catch {
            guard isExpectedAvailabilityError(
                error
            ) == false else {
                return
            }

            assertionFailure(
                error.localizedDescription
            )
        }
    }
}

private extension CookingSessionWatchSyncService {
    func canSendSnapshot(
        with session: WCSession
    ) -> Bool {
        session.activationState == .activated
            && session.isPaired
            && session.isWatchAppInstalled
    }

    func isExpectedAvailabilityError(
        _ error: Error
    ) -> Bool {
        guard let wcError = error as? WCError else {
            return false
        }

        switch wcError.code {
        case .deliveryFailed,
             .deviceNotPaired,
             .notReachable,
             .sessionNotActivated,
             .watchAppNotInstalled:
            return true
        default:
            return false
        }
    }
}
