import Foundation
import MHPlatform
import SwiftData

@MainActor
enum MainRouteService {
    static func makeRoutePipeline(
        navigationModel: MainNavigationModel,
        modelContext: ModelContext,
        logger: MHLogger
    ) -> MHAppRoutePipeline<CookleRoute> {
        let navigationRouter = MainNavigationRouter(
            navigationModel: navigationModel
        )
        let applyOnMainActor: MHAppRoutePipeline<CookleRoute>.RouteApplier = { resolvedRoute in
            try navigationRouter.apply(
                route: resolvedRoute,
                context: modelContext
            )
        }

        return .init(
            routeLifecycle: .init(
                logger: logger,
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
}
