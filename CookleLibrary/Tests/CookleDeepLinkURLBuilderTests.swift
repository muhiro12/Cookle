@testable import CookleLibrary
import Foundation
import Testing

@Suite("CookleDeepLinkURLBuilder")
struct CookleDeepLinkURLBuilderTests {
    @Test("Builds home route URL")
    func routeURLBuildsHomeURL() {
        let url = CookleDeepLinkURLBuilder.routeURL(for: .home)
        #expect(
            url?.absoluteString == "https://muhiro12.github.io/Cookle/home?"
        )
    }

    @Test("Builds preferred home URL")
    func preferredURLBuildsHomeURL() {
        let url = CookleDeepLinkURLBuilder.preferredURL(for: .home)
        #expect(
            url.absoluteString == "https://muhiro12.github.io/Cookle/home?"
        )
    }

    @Test("Builds recipe detail URL")
    func recipeDetailURLBuildsRecipeDetailURL() {
        let url = CookleDeepLinkURLBuilder.recipeDetailURL(for: "recipe-id")
        #expect(
            url?.absoluteString == "https://muhiro12.github.io/Cookle/recipe?id=recipe-id"
        )
    }

    @Test("Builds photo detail URL")
    func photoDetailURLBuildsPhotoDetailURL() {
        let url = CookleDeepLinkURLBuilder.photoDetailURL(for: "photo-id")
        #expect(
            url?.absoluteString == "https://muhiro12.github.io/Cookle/photo?id=photo-id"
        )
    }

    @Test("Builds tag detail URL")
    func tagDetailURLBuildsTagDetailURL() {
        let url = CookleDeepLinkURLBuilder.tagDetailURL(
            kind: .category,
            id: "category-id"
        )
        #expect(
            url?.absoluteString == "https://muhiro12.github.io/Cookle/tag/category?id=category-id"
        )
    }

    @Test("Builds preferred diary URL from date components")
    func preferredDiaryURLBuildsDiaryDateRoute() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current
        let date = calendar.date(
            from: .init(
                year: 2_026,
                month: 2,
                day: 27,
                hour: 0,
                minute: 0,
                second: 0
            )
        ) ?? .now

        let url = CookleDeepLinkURLBuilder.preferredDiaryURL(
            for: date,
            calendar: calendar
        )

        #expect(
            url.absoluteString == "https://muhiro12.github.io/Cookle/diary/2026-02-27?"
        )
    }
}
