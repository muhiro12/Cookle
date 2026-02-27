@testable import CookleLibrary
import Foundation
import Testing

@Suite("CookleWidgetDeepLink")
struct CookleWidgetDeepLinkTests {
    @Test("Creates the expected diary deep-link URL")
    func createsDiaryURL() {
        let diaryURL = CookleWidgetDeepLink.url(for: .diary)
        #expect(
            diaryURL?.absoluteString == "https://muhiro12.github.io/Cookle/diary"
        )
    }

    @Test("Parses widget destination from a valid recipe URL")
    func parsesDestination() throws {
        let deepLinkURL = try #require(
            URL(string: "cookle://recipe?id=recipe-id")
        )
        let destination = CookleWidgetDeepLink.destination(from: deepLinkURL)
        #expect(destination == .recipe)
    }

    @Test("Returns nil for invalid scheme")
    func invalidSchemeReturnsNil() throws {
        let deepLinkURL = try #require(URL(string: "https://widget/recipe"))
        let destination = CookleWidgetDeepLink.destination(from: deepLinkURL)
        #expect(destination == nil)
    }

    @Test("Returns nil for non-widget destination")
    func nonWidgetDestinationReturnsNil() throws {
        let deepLinkURL = try #require(URL(string: "cookle://settings"))
        let destination = CookleWidgetDeepLink.destination(from: deepLinkURL)
        #expect(destination == nil)
    }

    @Test("Returns nil for legacy widget URL")
    func legacyWidgetURLReturnsNil() throws {
        let deepLinkURL = try #require(URL(string: "cookle://widget/diary"))
        let destination = CookleWidgetDeepLink.destination(from: deepLinkURL)
        #expect(destination == nil)
    }
}
