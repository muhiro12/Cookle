import Combine
import Foundation
import WatchConnectivity

/// Owns the Watch's durable cooking session state and recent recipe cache,
/// and is the single Watch writer of the application context.
@MainActor
final class WatchCookingSessionStore: NSObject, ObservableObject, WCSessionDelegate {
    private let session: WCSession?
    private let userDefaults: UserDefaults?
    private let stateStorageKey: String
    private let catalogStorageKey: String

    @Published private(set) var localState: CookingSessionLocalState
    @Published private(set) var peerStatus: CookingSessionPeerStatus = .compatible
    /// The last accepted catalog. It is cached content prepared on iPhone,
    /// not a live view of the recipes.
    @Published private(set) var recentRecipeCatalog: RecentRecipeCatalog?

    var activeSnapshot: CookingSessionSnapshot? {
        localState.activeSnapshot
    }

    /// A different session started independently on iPhone.
    var conflictingSnapshot: CookingSessionSnapshot? {
        localState.pendingConflict?.snapshot
    }

    init(
        session: WCSession? = WCSession.isSupported() ? .default : nil,
        userDefaults: UserDefaults? = .standard,
        stateStorageKey: String = CookleUserDefaultsKeys.Standard.cookingSessionState.rawValue,
        catalogStorageKey: String = CookleUserDefaultsKeys.Standard.recentRecipeCatalog.rawValue
    ) {
        self.session = session
        self.userDefaults = userDefaults
        self.stateStorageKey = stateStorageKey
        self.catalogStorageKey = catalogStorageKey
        self.localState = userDefaults?
            .string(forKey: stateStorageKey)
            .flatMap(CookingSessionLocalState.decoded(from:))
            ?? .init()
        self.recentRecipeCatalog = userDefaults?
            .string(forKey: catalogStorageKey)
            .flatMap(RecentRecipeCatalog.decoded(from:))
        super.init()
        self.session?.delegate = self
        applyReceivedContext(
            session?.receivedApplicationContext ?? [:]
        )
        self.session?.activate()
    }

    #if DEBUG
    convenience init(
        previewSnapshot: CookingSessionSnapshot?,
        previewCatalog: RecentRecipeCatalog? = nil
    ) {
        self.init(session: nil, userDefaults: nil)
        self.localState = .migrating(legacySnapshot: previewSnapshot)
        self.recentRecipeCatalog = previewCatalog
    }
    #endif

    /// Starts cooking a cached recipe. Works offline; the start is sent when
    /// iPhone becomes reachable.
    func startSession(
        for recipe: RecentRecipe,
        startedAt: Date = .now
    ) {
        guard recipe.steps.isEmpty == false else {
            return
        }

        mutateState { state in
            state.start(
                recipe.startingSnapshot(startedAt: startedAt)
            )
            return true
        }
    }

    func setCurrentStepIndex(
        _ stepIndex: Int,
        updatedAt: Date = .now
    ) {
        updateActiveSession { snapshot in
            snapshot.settingCurrentStepIndex(
                stepIndex,
                updatedAt: updatedAt
            )
        }
    }

    func returnToPreviousStep(
        updatedAt: Date = .now
    ) {
        updateActiveSession { snapshot in
            snapshot.returningToPreviousStep(
                updatedAt: updatedAt
            )
        }
    }

    func advanceToNextStep(
        updatedAt: Date = .now
    ) {
        updateActiveSession { snapshot in
            snapshot.advancingToNextStep(
                updatedAt: updatedAt
            )
        }
    }

    func advanceFromTimerFollowUp(
        updatedAt: Date = .now
    ) {
        updateActiveSession { snapshot in
            snapshot
                .cancelingTimer(
                    updatedAt: updatedAt
                )
                .advancingToNextStep(
                    updatedAt: updatedAt
                )
        }
    }

    func startTimer(
        minutes: Int,
        startedAt: Date = .now
    ) {
        guard minutes > .zero else {
            return
        }

        updateActiveSession { snapshot in
            snapshot.startingTimer(
                durationMinutes: minutes,
                startedAt: startedAt
            )
        }
    }

    func cancelTimer(
        updatedAt: Date = .now
    ) {
        updateActiveSession { snapshot in
            snapshot.cancelingTimer(
                updatedAt: updatedAt
            )
        }
    }

    func repeatTimer(
        startedAt: Date = .now
    ) {
        updateActiveSession { snapshot in
            snapshot.repeatingTimer(
                startedAt: startedAt
            )
        }
    }

    func endSession(
        updatedAt: Date = .now
    ) {
        mutateState { state in
            state.endActiveSession(
                updatedAt: updatedAt
            )
        }
    }

    func resolveConflict(
        keepingLocalSession: Bool
    ) {
        mutateState { state in
            state.resolveConflict(
                keepingLocalSession: keepingLocalSession
            )
        }
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith _: WCSessionActivationState,
        error _: (any Error)?
    ) {
        let context = session.receivedApplicationContext.compactMapValues { $0 as? String }
        Task { @MainActor in
            self.applyReceivedContext(
                context
            )
            // Retry the latest local state after every activation.
            self.sendContext()
        }
    }

    nonisolated func session(
        _: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        let context = applicationContext.compactMapValues { $0 as? String }
        Task { @MainActor in
            self.applyReceivedContext(
                context
            )
        }
    }
}

private extension WatchCookingSessionStore {
    func applyReceivedContext(
        _ context: [String: Any]
    ) {
        if let receivedCatalog = WatchCompanionContext.recentRecipeCatalog(
            in: context
        ),
        receivedCatalog != recentRecipeCatalog {
            recentRecipeCatalog = receivedCatalog
            userDefaults?.set(
                receivedCatalog.encodedString(),
                forKey: catalogStorageKey
            )
        }

        var updatedState = localState
        let result = CookingSessionOperations.applyReceivedContext(
            context,
            to: &updatedState
        )
        if let receivedPeerStatus = result.peerStatus,
           receivedPeerStatus != peerStatus {
            peerStatus = receivedPeerStatus
        }
        guard result.changed else {
            return
        }
        mutateState { state in
            state = updatedState
            return true
        }
    }

    func updateActiveSession(
        _ transform: (CookingSessionSnapshot) -> CookingSessionSnapshot
    ) {
        mutateState { state in
            state.updateActiveSession(transform)
        }
    }

    /// Applies a state change, persists it, then sends it.
    func mutateState(
        _ mutation: (inout CookingSessionLocalState) -> Bool
    ) {
        var updatedState = localState
        guard mutation(&updatedState),
              updatedState != localState else {
            return
        }

        localState = updatedState
        if let encodedState = updatedState.encodedString() {
            userDefaults?.set(
                encodedState,
                forKey: stateStorageKey
            )
        }
        sendContext()
    }

    func sendContext() {
        guard let session,
              canSendContext(
                with: session
              ) else {
            return
        }

        do {
            try session.updateApplicationContext(
                WatchCompanionContext.composed(
                    sessionState: localState.shared
                )
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

    func canSendContext(
        with session: WCSession
    ) -> Bool {
        session.activationState == .activated
            && session.isCompanionAppInstalled
    }

    func isExpectedAvailabilityError(
        _ error: Error
    ) -> Bool {
        guard let wcError = error as? WCError else {
            return false
        }

        switch wcError.code {
        case .deliveryFailed,
             .notReachable,
             .sessionNotActivated,
             .watchAppNotInstalled:
            return true
        default:
            return false
        }
    }
}
