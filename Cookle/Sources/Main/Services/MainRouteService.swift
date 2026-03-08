import Foundation
import MHPlatform
import SwiftData

@MainActor
enum MainRouteService {
    private static let routeLifecycle = MHRouteLifecycle<CookleRoute>(
        logger: CookleApp.logger(
            category: "RouteExecution",
            source: #fileID
        ),
        isDuplicate: ==
    )

    static func activateRouteExecution(
        state: MainNavigationState,
        context: ModelContext,
        isRegularWidth: Bool
    ) async throws -> MainNavigationState {
        var nextState = state
        _ = try await routeLifecycle.activate { resolvedRoute in
            nextState = try apply(
                route: resolvedRoute,
                state: nextState,
                context: context,
                isRegularWidth: isRegularWidth
            )
        }
        return nextState
    }

    static func applyPendingRouteIfNeeded(
        from sources: MHDeepLinkSourceChain,
        state: MainNavigationState,
        context: ModelContext,
        isRegularWidth: Bool
    ) async throws -> MainNavigationState {
        var nextState = state
        guard try await routeLifecycle.submitLatest(
            from: sources,
            parse: { routeURL in
                CookleRouteParser.parse(url: routeURL)
            },
            applyOnMainActor: { resolvedRoute in
                nextState = try apply(
                    route: resolvedRoute,
                    state: nextState,
                    context: context,
                    isRegularWidth: isRegularWidth
                )
            }
        ) != nil else {
            return state
        }
        return nextState
    }
}

private extension MainRouteService {
    static func apply(
        route: CookleRoute,
        state: MainNavigationState,
        context: ModelContext,
        isRegularWidth: Bool
    ) throws -> MainNavigationState {
        let outcome = try CookleRouteExecutor.execute(
            route: route,
            context: context
        )
        var state = state
        applyRouteOutcome(
            outcome,
            state: &state,
            isRegularWidth: isRegularWidth
        )
        return state
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
