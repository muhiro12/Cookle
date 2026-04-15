import SwiftData

@MainActor
final class MainNavigationRouter {
    private let navigationModel: MainNavigationModel

    init(navigationModel: MainNavigationModel) {
        self.navigationModel = navigationModel
    }

    func apply(
        route: CookleRoute,
        context: ModelContext
    ) throws {
        let outcome = try CookleRouteExecutor.execute(
            route: route,
            context: context
        )
        apply(outcome)
    }

    func apply(
        _ outcome: CookleRouteOutcome
    ) {
        if !outcome.isSettingsRoute {
            navigationModel.incomingSettingsSelection = nil
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
                destination: nil
            )
        case .settingsSubscription:
            applySettingsRoute(
                destination: .subscription
            )
        case .settingsLicense:
            applySettingsRoute(
                destination: .license
            )
        }
    }
}

private extension MainNavigationRouter {
    func applySettingsRoute(
        destination: SettingsContent?
    ) {
        navigationModel.selectedTab = .settings
        navigationModel.incomingSettingsSelection = destination
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
