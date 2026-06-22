@testable import CookleLibrary
import Foundation
import Testing

@Suite("CookleRouteParser")
struct CookleRouteParserTests {
    @Test("Parses custom scheme home route")
    func parseCustomSchemeHomeRoute() {
        let route = CookleRouteParser.parse(
            url: testURL("cookle://home")
        )
        #expect(route == .home)
    }

    @Test("Parses custom scheme diary route")
    func parseCustomSchemeDiaryRoute() {
        let route = CookleRouteParser.parse(
            url: testURL("cookle://diary")
        )
        #expect(route == .diary)
    }

    @Test("Parses custom scheme diary date route")
    func parseCustomSchemeDiaryDateRoute() {
        let route = CookleRouteParser.parse(
            url: testURL("cookle://diary/2026-02-27")
        )
        #expect(route == .diaryDate(year: 2_026, month: 2, day: 27))
    }

    @Test("Parses custom scheme recipe detail route with query")
    func parseCustomSchemeRecipeDetailRoute() {
        let route = CookleRouteParser.parse(
            url: testURL("cookle://recipe?id=recipe-id")
        )
        #expect(route == .recipeDetail("recipe-id"))
    }

    @Test("Parses custom scheme search route with query")
    func parseCustomSchemeSearchRoute() {
        let route = CookleRouteParser.parse(
            url: testURL("cookle://search?q=soup")
        )
        #expect(route == .search(query: "soup"))
    }

    @Test("Parses custom scheme photo detail route with query")
    func parseCustomSchemePhotoDetailRoute() {
        let route = CookleRouteParser.parse(
            url: testURL("cookle://photo?id=photo-id")
        )
        #expect(route == .photoDetail("photo-id"))
    }

    @Test("Parses custom scheme category tag detail route with query")
    func parseCustomSchemeCategoryTagDetailRoute() {
        let route = CookleRouteParser.parse(
            url: testURL("cookle://tag/category?id=category-id")
        )
        #expect(route == .tagDetail(kind: .category, id: "category-id"))
    }

    @Test("Parses custom scheme ingredient tag list route")
    func parseCustomSchemeIngredientTagListRoute() {
        let route = CookleRouteParser.parse(
            url: testURL("cookle://tag/ingredient")
        )
        #expect(route == .tag(kind: .ingredient))
    }

    @Test("Parses custom scheme settings subscription route")
    func parseCustomSchemeSettingsSubscriptionRoute() {
        let route = CookleRouteParser.parse(
            url: testURL("cookle://settings/subscription")
        )
        #expect(route == .settingsSubscription)
    }

    @Test("Parses universal link route with path prefix")
    func parseUniversalLinkRouteWithPrefix() {
        let route = CookleRouteParser.parse(
            url: testURL("https://muhiro12.github.io/Cookle/recipe?id=recipe-id")
        )
        #expect(route == .recipeDetail("recipe-id"))
    }

    @Test("Parses universal link category tag route with path prefix")
    func parseUniversalLinkCategoryTagRouteWithPrefix() {
        let route = CookleRouteParser.parse(
            url: testURL("https://muhiro12.github.io/Cookle/tag/category?id=category-id")
        )
        #expect(route == .tagDetail(kind: .category, id: "category-id"))
    }

    @Test("Parses universal link route without path prefix")
    func parseUniversalLinkRouteWithoutPrefix() {
        let route = CookleRouteParser.parse(
            url: testURL("https://muhiro12.github.io/diary/2026-02-27")
        )
        #expect(route == .diaryDate(year: 2_026, month: 2, day: 27))
    }

    @Test("Defaults to home when URL has no destination")
    func parseDefaultsToHomeWhenNoDestination() {
        let customSchemeRoute = CookleRouteParser.parse(
            url: testURL("cookle://")
        )
        let universalLinkRoute = CookleRouteParser.parse(
            url: testURL("https://muhiro12.github.io/Cookle")
        )
        #expect(customSchemeRoute == .home)
        #expect(universalLinkRoute == .home)
    }

    @Test("Rejects unknown universal link host")
    func parseRejectsUnknownUniversalLinkHost() {
        let route = CookleRouteParser.parse(
            url: testURL("https://example.com/Cookle/recipe")
        )
        #expect(route == nil)
    }

    @Test("Rejects legacy widget deep-link URL")
    func parseRejectsLegacyWidgetURL() {
        let route = CookleRouteParser.parse(
            url: testURL("cookle://widget/diary")
        )
        #expect(route == nil)
    }

    @Test("Rejects invalid diary date")
    func parseRejectsInvalidDiaryDate() {
        let route = CookleRouteParser.parse(
            url: testURL("cookle://diary/2026-02-31")
        )
        #expect(route == nil)
    }

    @Test("Rejects route with extra path segments")
    func parseRejectsRouteWithExtraPathSegments() {
        let route = CookleRouteParser.parse(
            url: testURL("cookle://recipe/extra?id=recipe-id")
        )
        #expect(route == nil)
    }

    @Test("Rejects recipe route with empty id")
    func parseRejectsRecipeRouteWithEmptyID() {
        let route = CookleRouteParser.parse(
            url: testURL("cookle://recipe?id=")
        )
        #expect(route == nil)
    }

    @Test("Rejects photo route with empty id")
    func parseRejectsPhotoRouteWithEmptyID() {
        let route = CookleRouteParser.parse(
            url: testURL("cookle://photo?id=")
        )
        #expect(route == nil)
    }

    @Test("Rejects unknown tag kind route")
    func parseRejectsUnknownTagKindRoute() {
        let route = CookleRouteParser.parse(
            url: testURL("cookle://tag/course?id=tag-id")
        )
        #expect(route == nil)
    }

    @Test("Rejects tag route with extra path segments")
    func parseRejectsTagRouteWithExtraPathSegments() {
        let route = CookleRouteParser.parse(
            url: testURL("cookle://tag/category/extra?id=tag-id")
        )
        #expect(route == nil)
    }

    @Test("Rejects tag route with empty id")
    func parseRejectsTagRouteWithEmptyID() {
        let route = CookleRouteParser.parse(
            url: testURL("cookle://tag/category?id=")
        )
        #expect(route == nil)
    }
}

private func testURL(_ value: String) -> URL {
    guard let url = URL(string: value) else {
        fatalError("Invalid test URL: \(value)")
    }
    return url
}
