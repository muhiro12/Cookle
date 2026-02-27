import Foundation
import SwiftData

@MainActor
enum MainRouteService {
    static func applyPendingIntentRouteIfNeeded(
        state: inout MainNavigationState,
        context: ModelContext,
        isRegularWidth: Bool
    ) throws {
        guard let intentRouteURL = CookleIntentRouteStore.consume() else {
            return
        }
        try handleIncomingURL(
            intentRouteURL,
            state: &state,
            context: context,
            isRegularWidth: isRegularWidth
        )
    }

    static func handleIncomingURL(
        _ url: URL,
        state: inout MainNavigationState,
        context: ModelContext,
        isRegularWidth: Bool
    ) throws {
        guard let route = CookleRouteParser.parse(url: url) else {
            return
        }
        state.pendingRoute = route
        try applyPendingRouteIfNeeded(
            state: &state,
            context: context,
            isRegularWidth: isRegularWidth
        )
    }
}

private extension MainRouteService {
    static func applyPendingRouteIfNeeded(
        state: inout MainNavigationState,
        context: ModelContext,
        isRegularWidth: Bool
    ) throws {
        guard let pendingRoute = state.pendingRoute else {
            return
        }
        state.pendingRoute = nil
        let outcome = try CookleRouteExecutor.execute(
            route: pendingRoute,
            context: context
        )
        applyRouteOutcome(
            outcome,
            state: &state,
            isRegularWidth: isRegularWidth
        )
    }

    static func applyRouteOutcome(
        _ outcome: CookleRouteOutcome,
        state: inout MainNavigationState,
        isRegularWidth: Bool
    ) {
        if !outcome.isSettingsRoute {
            state.isCompactSettingsPresented = false
            state.compactSettingsSelection = nil
        }

        switch outcome {
        case .home:
            state.selectedTab = .diary
            state.selectedDiary = nil
            state.selectedDiaryRecipe = nil
            state.selectedRecipe = nil
            state.selectedSearchRecipe = nil
            state.incomingSearchQuery = nil
        case .diary(let diary):
            state.selectedTab = .diary
            state.selectedDiary = diary
            state.selectedDiaryRecipe = nil
        case .recipe(let recipe):
            state.selectedTab = .recipe
            state.selectedRecipe = recipe
        case .search(let query):
            state.selectedTab = .search
            state.selectedSearchRecipe = nil
            state.incomingSearchQuery = query
        case .settings:
            applySettingsRoute(
                destination: nil,
                state: &state,
                isRegularWidth: isRegularWidth
            )
        case .settingsSubscription:
            applySettingsRoute(
                destination: .subscription,
                state: &state,
                isRegularWidth: isRegularWidth
            )
        case .settingsLicense:
            applySettingsRoute(
                destination: .license,
                state: &state,
                isRegularWidth: isRegularWidth
            )
        }
    }

    static func applySettingsRoute(
        destination: SettingsContent?,
        state: inout MainNavigationState,
        isRegularWidth: Bool
    ) {
        if isRegularWidth {
            state.isCompactSettingsPresented = false
            state.compactSettingsSelection = nil
            state.selectedTab = .settings
            state.incomingSettingsSelection = destination
        } else {
            state.compactSettingsSelection = destination
            state.isCompactSettingsPresented = true
        }
    }
}

private extension CookleRouteOutcome {
    var isSettingsRoute: Bool {
        switch self {
        case .settings,
             .settingsSubscription,
             .settingsLicense:
            return true
        case .home,
             .diary,
             .recipe,
             .search:
            return false
        }
    }
}
