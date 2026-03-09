import Foundation
import MHAppRuntimeCore
import MHDeepLinking
import MHRouteExecution
import SwiftData

@MainActor
enum MainRouteService {
    static func makeRoutePipeline(
        navigationModel: MainNavigationModel,
        modelContext: ModelContext
    ) -> MHAppRoutePipeline<CookleRoute> {
        let applyOnMainActor: MHAppRoutePipeline<CookleRoute>.RouteApplier = { resolvedRoute in
            try apply(
                route: resolvedRoute,
                navigationModel: navigationModel,
                context: modelContext
            )
        }

        return .init(
            routeLifecycle: .init(
                logger: CookleApp.logger(
                    category: "RouteExecution",
                    source: #fileID
                ),
                isDuplicate: ==
            ),
            parse: { routeURL in
                CookleRouteParser.parse(url: routeURL)
            },
            pendingSources: pendingSources,
            applyOnMainActor: applyOnMainActor
        )
    }
}

private extension MainRouteService {
    static var pendingSources: [any MHDeepLinkURLSource] {
        var sources = [any MHDeepLinkURLSource]()

        if let intentRouteSource = CookleIntentRouteStore.source {
            sources.append(intentRouteSource)
        }

        return sources
    }

    static func apply(
        route: CookleRoute,
        navigationModel: MainNavigationModel,
        context: ModelContext
    ) throws {
        let outcome = try CookleRouteExecutor.execute(
            route: route,
            context: context
        )
        applyRouteOutcome(
            outcome,
            navigationModel: navigationModel
        )
    }

    static func applyRouteOutcome(
        _ outcome: CookleRouteOutcome,
        navigationModel: MainNavigationModel
    ) {
        if !outcome.isSettingsRoute {
            navigationModel.isCompactSettingsPresented = false
            navigationModel.compactSettingsSelection = nil
        }

        switch outcome {
        case .home:
            navigationModel.selectedTab = .diary
            navigationModel.selectedDiary = nil
            navigationModel.selectedDiaryRecipe = nil
            navigationModel.selectedRecipe = nil
            navigationModel.selectedSearchRecipe = nil
            navigationModel.incomingSearchQuery = nil
        case .diary(let diary):
            navigationModel.selectedTab = .diary
            navigationModel.selectedDiary = diary
            navigationModel.selectedDiaryRecipe = nil
        case .recipe(let recipe):
            navigationModel.selectedTab = .recipe
            navigationModel.selectedRecipe = recipe
        case .search(let query):
            navigationModel.selectedTab = .search
            navigationModel.selectedSearchRecipe = nil
            navigationModel.incomingSearchQuery = query
        case .settings:
            applySettingsRoute(
                destination: nil,
                navigationModel: navigationModel
            )
        case .settingsSubscription:
            applySettingsRoute(
                destination: .subscription,
                navigationModel: navigationModel
            )
        case .settingsLicense:
            applySettingsRoute(
                destination: .license,
                navigationModel: navigationModel
            )
        }
    }

    static func applySettingsRoute(
        destination: SettingsContent?,
        navigationModel: MainNavigationModel
    ) {
        if navigationModel.isRegularWidth {
            navigationModel.isCompactSettingsPresented = false
            navigationModel.compactSettingsSelection = nil
            navigationModel.selectedTab = .settings
            navigationModel.incomingSettingsSelection = destination
        } else {
            navigationModel.compactSettingsSelection = destination
            navigationModel.isCompactSettingsPresented = true
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
