@testable import CookleLibrary
import Foundation
import Testing

@Suite("CookleRouteURLBuilder")
struct CookleRouteURLBuilderTests {
    @Test("Builds custom scheme URL for diary date route")
    func buildCustomSchemeURLForDiaryDateRoute() {
        let route = CookleRoute.diaryDate(
            year: 2_026,
            month: 2,
            day: 27
        )
        let url = CookleRouteURLBuilder.customSchemeURL(for: route)
        #expect(
            url?.absoluteString == "cookle://diary/2026-02-27"
        )
    }

    @Test("Builds custom scheme URL for recipe detail route")
    func buildCustomSchemeURLForRecipeDetailRoute() {
        let route = CookleRoute.recipeDetail("recipe-id")
        let url = CookleRouteURLBuilder.customSchemeURL(for: route)
        #expect(
            url?.absoluteString == "cookle://recipe?id=recipe-id"
        )
    }

    @Test("Builds custom scheme URL for settings subscription route")
    func buildCustomSchemeURLForSettingsSubscriptionRoute() {
        let route = CookleRoute.settingsSubscription
        let url = CookleRouteURLBuilder.customSchemeURL(for: route)
        #expect(
            url?.absoluteString == "cookle://settings/subscription"
        )
    }

    @Test("Builds universal link URL for search route")
    func buildUniversalLinkURLForSearchRoute() {
        let route = CookleRoute.search(query: "ramen")
        let url = CookleRouteURLBuilder.universalLinkURL(
            for: route,
            host: "muhiro12.github.io",
            appPathPrefix: "Cookle"
        )
        #expect(
            url?.absoluteString == "https://muhiro12.github.io/Cookle/search?q=ramen"
        )
    }
}
