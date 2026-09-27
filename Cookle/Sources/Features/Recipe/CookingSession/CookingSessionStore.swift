import Foundation
import MHPlatform
import Observation

@MainActor
@Observable
final class CookingSessionStore {
    private let storageKey: String
    private let legacyStorageKey: String
    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let persistsSnapshot: Bool
    @ObservationIgnored private var stateChangeHandler: ((CookingSessionSyncState) -> Void)?
    @ObservationIgnored private var timerDeliveryHandler: ((_ isUserStartedTimer: Bool) -> Void)?

    private(set) var localState: CookingSessionLocalState
    private(set) var peerStatus: CookingSessionPeerStatus = .compatible

    var snapshot: CookingSessionSnapshot? {
        localState.shared.current?.snapshot
    }

    var activeSnapshot: CookingSessionSnapshot? {
        localState.activeSnapshot
    }

    /// A different session started independently on the paired Watch.
    var conflictingSnapshot: CookingSessionSnapshot? {
        localState.pendingConflict?.snapshot
    }

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = MHPreferenceDescriptors().cookingSessionState.storageKey,
        legacyStorageKey: String = MHPreferenceDescriptors().activeCookingSessionSnapshot.storageKey,
        initialSnapshot: CookingSessionSnapshot? = nil,
        persistsSnapshot: Bool = true
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        self.legacyStorageKey = legacyStorageKey
        self.persistsSnapshot = persistsSnapshot

        if let initialSnapshot {
            localState = .migrating(
                legacySnapshot: initialSnapshot
            )
        } else if persistsSnapshot {
            localState = Self.restoredState(
                from: userDefaults,
                storageKey: storageKey,
                legacyStorageKey: legacyStorageKey
            )
        } else {
            localState = .init()
        }
    }

    func isActiveSession(
        for recipe: Recipe
    ) -> Bool {
        activeSnapshot?.recipeID == RecipeStableIdentifierCodec.stableIdentifier(
            for: recipe
        )
    }

    func startSession(
        for recipe: Recipe,
        startedAt: Date = .now
    ) {
        guard !recipe.steps.isEmpty else {
            return
        }

        mutateState { state in
            state.start(
                .init(
                    recipeID: RecipeStableIdentifierCodec.stableIdentifier(
                        for: recipe
                    ),
                    recipeName: recipe.name,
                    steps: recipe.steps,
                    currentStepIndex: .zero,
                    activeTimer: nil,
                    updatedAt: startedAt,
                    isActive: true
                )
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

        updateActiveSession(isUserStartedTimer: true) { snapshot in
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
        updateActiveSession(isUserStartedTimer: true) { snapshot in
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

    func applyReceivedContext(
        _ context: [String: Any]
    ) {
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

    func setStateChangeHandler(
        _ handler: ((CookingSessionSyncState) -> Void)?
    ) {
        stateChangeHandler = handler
    }

    /// Sets the handler told about every applied change, local or received.
    /// `isUserStartedTimer` is `true` only when the person started or
    /// repeated a timer on this device.
    func setTimerDeliveryHandler(
        _ handler: ((_ isUserStartedTimer: Bool) -> Void)?
    ) {
        timerDeliveryHandler = handler
    }
}

private extension CookingSessionStore {
    static func restoredState(
        from userDefaults: UserDefaults,
        storageKey: String,
        legacyStorageKey: String
    ) -> CookingSessionLocalState {
        if let value = userDefaults.string(
            forKey: storageKey
        ),
        let state = CookingSessionLocalState.decoded(
            from: value
        ) {
            return state
        }

        let legacySnapshot = userDefaults.string(
            forKey: legacyStorageKey
        )
        .flatMap(CookingSessionSnapshot.decoded(from:))
        return .migrating(
            legacySnapshot: legacySnapshot
        )
    }

    func updateActiveSession(
        isUserStartedTimer: Bool = false,
        _ transform: (CookingSessionSnapshot) -> CookingSessionSnapshot
    ) {
        mutateState(isUserStartedTimer: isUserStartedTimer) { state in
            state.updateActiveSession(transform)
        }
    }

    /// Applies a state change, persists it, then hands the shared state to
    /// the sync writer so a relaunch never loses a change that was sent.
    func mutateState(
        isUserStartedTimer: Bool = false,
        _ mutation: (inout CookingSessionLocalState) -> Bool
    ) {
        var updatedState = localState
        guard mutation(&updatedState),
              updatedState != localState else {
            return
        }

        localState = updatedState
        persistState()
        stateChangeHandler?(updatedState.shared)
        timerDeliveryHandler?(isUserStartedTimer)
    }

    func persistState() {
        guard persistsSnapshot else {
            return
        }

        if let encodedState = localState.encodedString() {
            userDefaults.set(
                encodedState,
                forKey: storageKey
            )
        }
        // Keep the earlier key readable for local recovery by an older build.
        if let encodedSnapshot = activeSnapshot?.encodedString() {
            userDefaults.set(
                encodedSnapshot,
                forKey: legacyStorageKey
            )
        } else {
            userDefaults.removeObject(
                forKey: legacyStorageKey
            )
        }
    }
}
