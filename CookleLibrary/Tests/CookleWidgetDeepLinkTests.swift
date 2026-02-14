@testable import CookleLibrary
import Foundation
import Testing

@Suite("CookleWidgetDeepLink")
struct CookleWidgetDeepLinkTests {
    @Test("Creates the expected diary deep-link URL")
    func createsDiaryURL() {
        let diaryURL = CookleWidgetDeepLink.url(for: .diary)
        #expect(diaryURL?.absoluteString == "cookle://widget/diary")
    }

    @Test("Parses widget destination from a valid URL")
    func parsesDestination() throws {
        let deepLinkURL = try #require(URL(string: "cookle://widget/recipe"))
        let destination = CookleWidgetDeepLink.destination(from: deepLinkURL)
        #expect(destination == .recipe)
    }

    @Test("Returns nil for invalid scheme")
    func invalidSchemeReturnsNil() throws {
        let deepLinkURL = try #require(URL(string: "https://widget/recipe"))
        let destination = CookleWidgetDeepLink.destination(from: deepLinkURL)
        #expect(destination == nil)
    }

    @Test("Returns nil for unknown destination")
    func unknownDestinationReturnsNil() throws {
        let deepLinkURL = try #require(URL(string: "cookle://widget/settings"))
        let destination = CookleWidgetDeepLink.destination(from: deepLinkURL)
        #expect(destination == nil)
    }
}
