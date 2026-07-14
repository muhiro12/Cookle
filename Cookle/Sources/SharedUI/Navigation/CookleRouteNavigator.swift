import MHPlatform
import Observation
import SwiftData

@MainActor
@Observable
final class CookleRouteNavigator {
    static let disabled = CookleRouteNavigator()

    private let navigationRouter: MainNavigationRouter?
    private let modelContext: ModelContext?
    private let logger: MHLogger?

    init(
        navigationModel: MainNavigationModel,
        modelContext: ModelContext,
        logger: MHLogger
    ) {
        navigationRouter = MainNavigationRouter(
            navigationModel: navigationModel
        )
        self.modelContext = modelContext
        self.logger = logger
    }

    private init() {
        navigationRouter = nil
        modelContext = nil
        logger = nil
    }

    func open(_ route: CookleRoute) {
        guard let navigationRouter,
              let modelContext else {
            return
        }

        do {
            try navigationRouter.apply(
                route: route,
                context: modelContext
            )
        } catch {
            logger?.error(
                "in-app route execution failed",
                metadata: [
                    "error": error.localizedDescription
                ]
            )
        }
    }
}
