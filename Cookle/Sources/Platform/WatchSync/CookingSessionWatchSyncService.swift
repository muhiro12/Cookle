import Foundation
import MHPlatform
import SwiftData
import WatchConnectivity

/// The single iPhone writer of the Watch application context.
///
/// Every update sends the complete composed context: the durable cooking
/// session state and the recent recipe catalog. Application context replaces
/// the previous dictionary, so sending only one part would drop the other.
@MainActor
final class CookingSessionWatchSyncService: NSObject, WCSessionDelegate {
    private let cookingSessionStore: CookingSessionStore
    private let modelContext: ModelContext?
    private let userDefaults: UserDefaults
    private let recentRecipeIDsKey: String
    private let session: WCSession?
    private var recentRecipeCatalog: RecentRecipeCatalog?
    private var saveObserver: (any NSObjectProtocol)?

    init(
        cookingSessionStore: CookingSessionStore,
        modelContext: ModelContext? = nil,
        userDefaults: UserDefaults = .standard,
        recentRecipeIDsKey: String = MHPreferenceDescriptors().recentRecipeIDs.storageKey,
        session: WCSession? = WCSession.isSupported() ? .default : nil
    ) {
        self.cookingSessionStore = cookingSessionStore
        self.modelContext = modelContext
        self.userDefaults = userDefaults
        self.recentRecipeIDsKey = recentRecipeIDsKey
        self.session = session
        super.init()
        self.session?.delegate = self
        cookingSessionStore.setStateChangeHandler { [weak self] _ in
            self?.sendContext()
        }
        if let modelContext {
            saveObserver = NotificationCenter.default.addObserver(
                forName: ModelContext.didSave,
                object: modelContext,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.refreshRecentRecipes()
                }
            }
        }
        cookingSessionStore.applyReceivedContext(
            session?.receivedApplicationContext ?? [:]
        )
        refreshRecentRecipes(sends: false)
        self.session?.activate()
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith _: WCSessionActivationState,
        error _: (any Error)?
    ) {
        let context = session.receivedApplicationContext.compactMapValues { $0 as? String }
        Task { @MainActor in
            self.cookingSessionStore.applyReceivedContext(
                context
            )
            self.refreshRecentRecipes(sends: false)
            // Retry the latest composed context after every activation.
            self.sendContext()
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
        let context = applicationContext.compactMapValues { $0 as? String }
        Task { @MainActor in
            self.cookingSessionStore.applyReceivedContext(
                context
            )
        }
    }

    /// Moves an opened recipe to the front of the recent list sent to Watch.
    /// Opening a recipe never starts or changes a cooking session.
    func recordOpenedRecipe(
        _ recipe: Recipe
    ) {
        var history = storedHistory()
        history.recordOpened(
            CookingSessionOperations.recentRecipeID(for: recipe)
        )
        storeHistory(history)
        refreshRecentRecipes()
    }

    /// Rebuilds the recent recipe catalog from current recipes so edits and
    /// deletions reach Watch. An empty catalog is sent as authoritative.
    func refreshRecentRecipes(
        sends: Bool = true
    ) {
        guard let modelContext else {
            return
        }
        do {
            let result = try CookingSessionOperations.recentRecipeCatalog(
                history: storedHistory(),
                context: modelContext
            )
            storeHistory(result.history)
            let previousRecipes = recentRecipeCatalog?.recipes
            recentRecipeCatalog = result.catalog
            if sends,
               previousRecipes != result.catalog.recipes {
                sendContext()
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }
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
                    sessionState: cookingSessionStore.localState.shared,
                    recentRecipeCatalog: recentRecipeCatalog
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
}

private extension CookingSessionWatchSyncService {
    func storedHistory() -> RecentRecipeHistory {
        let recipeIDs = userDefaults.string(
            forKey: recentRecipeIDsKey
        )
        .flatMap { value in
            try? JSONDecoder().decode(
                [String].self,
                from: Data(value.utf8)
            )
        }
        return .init(
            recipeIDs: recipeIDs ?? []
        )
    }

    func storeHistory(
        _ history: RecentRecipeHistory
    ) {
        guard let data = try? JSONEncoder().encode(history.recipeIDs),
              let value = String(bytes: data, encoding: .utf8) else {
            return
        }
        userDefaults.set(
            value,
            forKey: recentRecipeIDsKey
        )
    }

    func canSendContext(
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
