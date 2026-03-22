import CookleLibrary
import SwiftData
import XCTest

@testable import Cookle

final class CookleRoutePipelineSmokeTests: XCTestCase {
    @MainActor
    func testSearchDeepLinkUpdatesNavigationState() async throws {
        let context = try makeTestContext()
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

        XCTAssertEqual(
            navigationModel.selectedTab,
            .search
        )
        XCTAssertEqual(
            navigationModel.incomingSearchQuery,
            "curry"
        )
        XCTAssertNil(
            navigationModel.selectedSearchRecipe
        )
    }

    @MainActor
    func testInvalidDeepLinkRecordsParseFailure() async throws {
        let context = try makeTestContext()
        let navigationModel = MainNavigationModel()
        let routePipeline = MainRouteService.makeRoutePipeline(
            navigationModel: navigationModel,
            modelContext: context
        )
        let invalidURL = try XCTUnwrap(
            URL(string: "cookle://unsupported")
        )

        await routePipeline.inbox.ingest(invalidURL)
        _ = await routePipeline.synchronizePendingRoutesIfPossible()

        XCTAssertEqual(
            routePipeline.lastParseFailureURL,
            invalidURL
        )
    }
}

private extension CookleRoutePipelineSmokeTests {
    @MainActor
    func makeTestContext() throws -> ModelContext {
        let schema = Schema(
            [
                Recipe.self,
                Diary.self,
                DiaryObject.self,
                Category.self,
                Ingredient.self,
                IngredientObject.self,
                Photo.self,
                PhotoObject.self
            ]
        )
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        return .init(container)
    }
}
