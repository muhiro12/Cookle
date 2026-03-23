import CookleLibrary
import Foundation
import Testing

@testable import Cookle

@MainActor
struct CookleRoutePipelineSmokeTests {
    @Test
    func searchDeepLinkUpdatesNavigationState() async throws {
        let context = try makeCookleTestContext()
        let navigationModel = MainNavigationModel()
        let routePipeline = MainRouteService.makeRoutePipeline(
            navigationModel: navigationModel,
            modelContext: context
        )

        await routePipeline.inbox.ingest(
            CookleDeepLinkURLBuilder.preferredSearchURL(
                query: "curry"
            )
        )
        _ = await routePipeline.synchronizePendingRoutesIfPossible()

        #expect(navigationModel.selectedTab == .search)
        #expect(navigationModel.incomingSearchQuery == "curry")
        #expect(navigationModel.selectedSearchRecipe == nil)
    }

    @Test
    func invalidDeepLinkRecordsParseFailure() async throws {
        let context = try makeCookleTestContext()
        let navigationModel = MainNavigationModel()
        let routePipeline = MainRouteService.makeRoutePipeline(
            navigationModel: navigationModel,
            modelContext: context
        )
        let invalidURL = try #require(
            URL(string: "cookle://unsupported")
        )

        await routePipeline.inbox.ingest(
            invalidURL
        )
        _ = await routePipeline.synchronizePendingRoutesIfPossible()

        #expect(routePipeline.lastParseFailureURL == invalidURL)
    }
}
