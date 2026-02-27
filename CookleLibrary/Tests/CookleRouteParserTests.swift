@testable import CookleLibrary
import Foundation
import Testing

@Suite("CookleRouteParser")
struct CookleRouteParserTests {
    @Test("Parses custom scheme home route")
    func parseCustomSchemeHomeRoute() {
        let route = CookleRouteParser.parse(
            url: .init(string: "cookle://home")!
        )
        #expect(route == .home)
    }

    @Test("Parses custom scheme diary route")
    func parseCustomSchemeDiaryRoute() {
        let route = CookleRouteParser.parse(
            url: .init(string: "cookle://diary")!
        )
        #expect(route == .diary)
    }

    @Test("Parses custom scheme diary date route")
    func parseCustomSchemeDiaryDateRoute() {
        let route = CookleRouteParser.parse(
            url: .init(string: "cookle://diary/2026-02-27")!
        )
        #expect(route == .diaryDate(year: 2_026, month: 2, day: 27))
    }

    @Test("Parses custom scheme recipe detail route with query")
    func parseCustomSchemeRecipeDetailRoute() {
        let route = CookleRouteParser.parse(
            url: .init(string: "cookle://recipe?id=recipe-id")!
        )
        #expect(route == .recipeDetail("recipe-id"))
    }

    @Test("Parses custom scheme search route with query")
    func parseCustomSchemeSearchRoute() {
        let route = CookleRouteParser.parse(
            url: .init(string: "cookle://search?q=soup")!
        )
        #expect(route == .search(query: "soup"))
    }

    @Test("Parses custom scheme settings subscription route")
    func parseCustomSchemeSettingsSubscriptionRoute() {
        let route = CookleRouteParser.parse(
            url: .init(string: "cookle://settings/subscription")!
        )
        #expect(route == .settingsSubscription)
    }

    @Test("Parses universal link route with path prefix")
    func parseUniversalLinkRouteWithPrefix() {
        let route = CookleRouteParser.parse(
            url: .init(string: "https://muhiro12.github.io/Cookle/recipe?id=recipe-id")!
        )
        #expect(route == .recipeDetail("recipe-id"))
    }

    @Test("Parses universal link route without path prefix")
    func parseUniversalLinkRouteWithoutPrefix() {
        let route = CookleRouteParser.parse(
            url: .init(string: "https://muhiro12.github.io/diary/2026-02-27")!
        )
        #expect(route == .diaryDate(year: 2_026, month: 2, day: 27))
    }

    @Test("Defaults to home when URL has no destination")
    func parseDefaultsToHomeWhenNoDestination() {
        let customSchemeRoute = CookleRouteParser.parse(
            url: .init(string: "cookle://")!
        )
        let universalLinkRoute = CookleRouteParser.parse(
            url: .init(string: "https://muhiro12.github.io/Cookle")!
        )
        #expect(customSchemeRoute == .home)
        #expect(universalLinkRoute == .home)
    }

    @Test("Rejects unknown universal link host")
    func parseRejectsUnknownUniversalLinkHost() {
        let route = CookleRouteParser.parse(
            url: .init(string: "https://example.com/Cookle/recipe")!
        )
        #expect(route == nil)
    }

    @Test("Rejects legacy widget deep-link URL")
    func parseRejectsLegacyWidgetURL() {
        let route = CookleRouteParser.parse(
            url: .init(string: "cookle://widget/diary")!
        )
        #expect(route == nil)
    }

    @Test("Rejects invalid diary date")
    func parseRejectsInvalidDiaryDate() {
        let route = CookleRouteParser.parse(
            url: .init(string: "cookle://diary/2026-02-31")!
        )
        #expect(route == nil)
    }

    @Test("Rejects route with extra path segments")
    func parseRejectsRouteWithExtraPathSegments() {
        let route = CookleRouteParser.parse(
            url: .init(string: "cookle://recipe/extra?id=recipe-id")!
        )
        #expect(route == nil)
    }

    @Test("Rejects recipe route with empty id")
    func parseRejectsRecipeRouteWithEmptyID() {
        let route = CookleRouteParser.parse(
            url: .init(string: "cookle://recipe?id=")!
        )
        #expect(route == nil)
    }
}
