import CookleLibrary
import Testing

@testable import Cookle

@MainActor
struct MainNavigationRouterTests {
    @Test
    func apply_searchRoute_clearsPendingSettingsSelection() throws {
        let context = try makeCookleTestContext()
        let recipe = Recipe.create(
            context: context,
            name: "Curry",
            photos: [],
            servingSize: 2,
            cookingTime: 20,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        let navigationModel = MainNavigationModel()
        navigationModel.incomingSettingsSelection = .license
        navigationModel.selectedRecipe = recipe

        MainNavigationRouter(
            navigationModel: navigationModel
        ).apply(
            .search(query: "curry")
        )

        #expect(navigationModel.selectedTab == .search)
        #expect(navigationModel.incomingSearchQuery == "curry")
        #expect(navigationModel.incomingSettingsSelection == nil)
    }

    @Test
    func apply_settingsRoute_selectsSettingsTab() {
        let navigationModel = MainNavigationModel()

        MainNavigationRouter(
            navigationModel: navigationModel
        ).apply(
            .settingsSubscription
        )

        #expect(navigationModel.selectedTab == .settings)
        #expect(navigationModel.incomingSettingsSelection == .subscription)
    }

    @Test
    func apply_settingsRoute_updatesCompactWidthNavigation() {
        let navigationModel = MainNavigationModel()

        MainNavigationRouter(
            navigationModel: navigationModel
        ).apply(
            .settingsLicense
        )

        #expect(navigationModel.selectedTab == .settings)
        #expect(navigationModel.incomingSettingsSelection == .license)
    }
}
