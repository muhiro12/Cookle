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
        let logging = CookleAppLogging.preview()
        let routePipeline = MainRouteService.makeRoutePipeline(
            navigationModel: navigationModel,
            modelContext: context,
            logger: logging.logger(
                category: "RouteExecution",
                source: #fileID
            )
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
        let logging = CookleAppLogging.preview()
        let routePipeline = MainRouteService.makeRoutePipeline(
            navigationModel: navigationModel,
            modelContext: context,
            logger: logging.logger(
                category: "RouteExecution",
                source: #fileID
            )
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
