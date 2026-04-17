import Combine
import Foundation
import WatchConnectivity

@MainActor
final class WatchCookingSessionStore: NSObject, ObservableObject, WCSessionDelegate {
    private let session: WCSession?

    @Published private(set) var snapshot: WatchCookingSessionSnapshot?

    var activeSnapshot: WatchCookingSessionSnapshot? {
        guard let snapshot,
              snapshot.isActive else {
            return nil
        }

        return snapshot
    }

    init(
        session: WCSession? = WCSession.isSupported() ? .default : nil
    ) {
        self.session = session
        self.snapshot = nil
        super.init()
        self.session?.delegate = self
        applyApplicationContext(
            session?.receivedApplicationContext ?? [:]
        )
        self.session?.activate()
    }

    func setCurrentStepIndex(
        _ stepIndex: Int,
        updatedAt: Date = .now
    ) {
        guard let activeSnapshot else {
            return
        }

        applySnapshot(
            activeSnapshot.settingCurrentStepIndex(
                stepIndex,
                updatedAt: updatedAt
            )
        )
    }

    func returnToPreviousStep(
        updatedAt: Date = .now
    ) {
        guard let activeSnapshot else {
            return
        }

        applySnapshot(
            activeSnapshot.returningToPreviousStep(
                updatedAt: updatedAt
            )
        )
    }

    func advanceToNextStep(
        updatedAt: Date = .now
    ) {
        guard let activeSnapshot else {
            return
        }

        applySnapshot(
            activeSnapshot.advancingToNextStep(
                updatedAt: updatedAt
            )
        )
    }

    func advanceFromTimerFollowUp(
        updatedAt: Date = .now
    ) {
        guard let activeSnapshot else {
            return
        }

        let clearedSnapshot = activeSnapshot.cancelingTimer(
            updatedAt: updatedAt
        )
        applySnapshot(
            clearedSnapshot.advancingToNextStep(
                updatedAt: updatedAt
            )
        )
    }

    func startTimer(
        minutes: Int,
        startedAt: Date = .now
    ) {
        guard let activeSnapshot,
              minutes > .zero else {
            return
        }

        applySnapshot(
            activeSnapshot.startingTimer(
                durationMinutes: minutes,
                startedAt: startedAt
            )
        )
    }

    func cancelTimer(
        updatedAt: Date = .now
    ) {
        guard let activeSnapshot else {
            return
        }

        applySnapshot(
            activeSnapshot.cancelingTimer(
                updatedAt: updatedAt
            )
        )
    }

    func repeatTimer(
        startedAt: Date = .now
    ) {
        guard let activeSnapshot else {
            return
        }

        applySnapshot(
            activeSnapshot.repeatingTimer(
                startedAt: startedAt
            )
        )
    }

    func endSession(
        updatedAt: Date = .now
    ) {
        guard let snapshot else {
            return
        }

        applySnapshot(
            snapshot.endingSession(
                updatedAt: updatedAt
            )
        )
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
            self.pushSnapshot(
                self.snapshot
            )
        }
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

    private func applyApplicationContext(
        _ applicationContext: [String: Any]
    ) {
        let encodedSnapshot = applicationContext[
            "activeCookingSessionSnapshot"
        ] as? String
        applyEncodedSnapshot(
            encodedSnapshot
        )
    }

    private func applyEncodedSnapshot(
        _ encodedSnapshot: String?
    ) {
        guard let encodedSnapshot else {
            return
        }

        guard encodedSnapshot.isEmpty == false else {
            applySnapshot(nil)
            return
        }

        guard let incomingSnapshot = WatchCookingSessionSnapshot.decoded(
            from: encodedSnapshot
        ) else {
            return
        }

        let mergedSnapshot = if let snapshot {
            snapshot.merging(
                with: incomingSnapshot
            )
        } else {
            incomingSnapshot
        }
        applySnapshot(
            mergedSnapshot
        )
    }

    private func applySnapshot(
        _ updatedSnapshot: WatchCookingSessionSnapshot?
    ) {
        guard snapshot != updatedSnapshot else {
            return
        }

        snapshot = updatedSnapshot
        pushSnapshot(
            updatedSnapshot
        )
    }

    private func pushSnapshot(
        _ snapshot: WatchCookingSessionSnapshot?
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
