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
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
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
        _ session: WCSession
    ) {
    }

    nonisolated func sessionDidDeactivate(
        _ session: WCSession
    ) {
        session.activate()
    }

    nonisolated func session(
        _ session: WCSession,
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
        guard let session else {
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
            assertionFailure(
                error.localizedDescription
            )
        }
    }
}
