import CookleLibrary
import Testing

@testable import Cookle

@MainActor
struct MainNavigationRouterTests {
    @Test
    func apply_searchRoute_resetsCompactSettingsState() throws {
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
        navigationModel.isCompactSettingsPresented = true
        navigationModel.compactSettingsSelection = .license
        navigationModel.selectedRecipe = recipe

        MainNavigationRouter(
            navigationModel: navigationModel
        ).apply(
            .search(query: "curry")
        )

        #expect(navigationModel.selectedTab == .search)
        #expect(navigationModel.incomingSearchQuery == "curry")
        #expect(navigationModel.isCompactSettingsPresented == false)
        #expect(navigationModel.compactSettingsSelection == nil)
    }

    @Test
    func apply_settingsRoute_updatesRegularWidthNavigation() {
        let navigationModel = MainNavigationModel()
        navigationModel.isRegularWidth = true

        MainNavigationRouter(
            navigationModel: navigationModel
        ).apply(
            .settingsSubscription
        )

        #expect(navigationModel.selectedTab == .settings)
        #expect(navigationModel.incomingSettingsSelection == .subscription)
        #expect(navigationModel.isCompactSettingsPresented == false)
        #expect(navigationModel.compactSettingsSelection == nil)
    }

    @Test
    func apply_settingsRoute_presentsCompactSheetOnPhoneWidth() {
        let navigationModel = MainNavigationModel()
        navigationModel.isRegularWidth = false

        MainNavigationRouter(
            navigationModel: navigationModel
        ).apply(
            .settingsLicense
        )

        #expect(navigationModel.isCompactSettingsPresented)
        #expect(navigationModel.compactSettingsSelection == .license)
        #expect(navigationModel.selectedTab == .diary)
    }
}
