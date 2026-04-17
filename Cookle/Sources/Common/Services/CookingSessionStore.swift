import Foundation
import MHPlatform
import Observation

@MainActor
@Observable
final class CookingSessionStore {
    private let storageKey: String
    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let persistsSnapshot: Bool
    @ObservationIgnored private var snapshotChangeHandler: ((CookingSessionSnapshot?) -> Void)?

    private(set) var snapshot: CookingSessionSnapshot?

    var activeSnapshot: CookingSessionSnapshot? {
        guard let snapshot,
              snapshot.isActive else {
            return nil
        }

        return snapshot
    }

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = MHPreferenceDescriptors().activeCookingSessionSnapshot.storageKey,
        initialSnapshot: CookingSessionSnapshot? = nil,
        persistsSnapshot: Bool = true
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        self.persistsSnapshot = persistsSnapshot

        if let initialSnapshot {
            snapshot = initialSnapshot
        } else if persistsSnapshot {
            snapshot = Self.restoredSnapshot(
                from: userDefaults,
                storageKey: storageKey
            )
        } else {
            snapshot = nil
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
        guard recipe.steps.isNotEmpty else {
            return
        }

        applySnapshot(
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

    func applyIncomingSnapshot(
        _ incomingSnapshot: CookingSessionSnapshot
    ) {
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

    func setSnapshotChangeHandler(
        _ handler: ((CookingSessionSnapshot?) -> Void)?
    ) {
        snapshotChangeHandler = handler
    }
}

private extension CookingSessionStore {
    static func restoredSnapshot(
        from userDefaults: UserDefaults,
        storageKey: String
    ) -> CookingSessionSnapshot? {
        guard let value = userDefaults.string(
            forKey: storageKey
        ) else {
            return nil
        }

        return CookingSessionSnapshot.decoded(
            from: value
        )
    }

    func applySnapshot(
        _ updatedSnapshot: CookingSessionSnapshot?
    ) {
        guard snapshot != updatedSnapshot else {
            return
        }

        snapshot = updatedSnapshot
        persistSnapshot()
        snapshotChangeHandler?(updatedSnapshot)
    }

    func persistSnapshot() {
        guard persistsSnapshot else {
            return
        }

        guard let encodedSnapshot = snapshot?.encodedString() else {
            userDefaults.removeObject(
                forKey: storageKey
            )
            return
        }

        userDefaults.set(
            encodedSnapshot,
            forKey: storageKey
        )
    }
}
