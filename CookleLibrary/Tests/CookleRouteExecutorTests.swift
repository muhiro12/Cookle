@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("CookleRouteExecutor")
struct CookleRouteExecutorTests {
    let context: ModelContext = makeTestContext()

    @Test("Resolves diary date route to diary detail")
    func executeResolvesDiaryDateRoute() throws {
        let calendar = Calendar.current
        let date = try #require(
            calendar.date(
                from: .init(
                    year: 2_026,
                    month: 2,
                    day: 27,
                    hour: 12,
                    minute: 0,
                    second: 0
                )
            )
        )
        let diary = Diary.create(
            context: context,
            date: date,
            objects: [],
            note: "Note"
        )

        let outcome = try CookleRouteExecutor.execute(
            route: .diaryDate(year: 2_026, month: 2, day: 27),
            context: context
        )

        switch outcome {
        case .diary(let resolvedDiary):
            let resolvedDiary = try #require(resolvedDiary)
            #expect(
                resolvedDiary.persistentModelID ==
                    diary.persistentModelID
            )
        case .home,
             .recipe,
             .search,
             .settings,
             .settingsSubscription,
             .settingsLicense:
            Issue.record("Expected .diary outcome for diary date route.")
        }
    }

    @Test("Falls back to diary list when diary date route has no matching diary")
    func executeFallsBackToDiaryListWhenDiaryNotFound() throws {
        let outcome = try CookleRouteExecutor.execute(
            route: .diaryDate(year: 2_026, month: 2, day: 27),
            context: context
        )

        switch outcome {
        case .diary(let resolvedDiary):
            #expect(resolvedDiary == nil)
        case .home,
             .recipe,
             .search,
             .settings,
             .settingsSubscription,
             .settingsLicense:
            Issue.record("Expected .diary fallback outcome when diary is missing.")
        }
    }

    @Test("Resolves recipe detail route to recipe detail")
    func executeResolvesRecipeDetailRoute() throws {
        let recipe = Recipe.create(
            context: context,
            name: "Pancakes",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        let recipeID = try recipe.id.base64Encoded()

        let outcome = try CookleRouteExecutor.execute(
            route: .recipeDetail(recipeID),
            context: context
        )

        switch outcome {
        case .recipe(let resolvedRecipe):
            let resolvedRecipe = try #require(resolvedRecipe)
            #expect(
                resolvedRecipe.persistentModelID ==
                    recipe.persistentModelID
            )
        case .home,
             .diary,
             .search,
             .settings,
             .settingsSubscription,
             .settingsLicense:
            Issue.record("Expected .recipe outcome for recipe detail route.")
        }
    }

    @Test("Falls back to recipe list for invalid recipe detail route")
    func executeFallsBackToRecipeListForInvalidRecipeRoute() throws {
        let outcome = try CookleRouteExecutor.execute(
            route: .recipeDetail("invalid"),
            context: context
        )

        switch outcome {
        case .recipe(let resolvedRecipe):
            #expect(resolvedRecipe == nil)
        case .home,
             .diary,
             .search,
             .settings,
             .settingsSubscription,
             .settingsLicense:
            Issue.record("Expected .recipe fallback outcome for invalid recipe route.")
        }
    }

    @Test("Returns search outcome for search route")
    func executeReturnsSearchOutcomeForSearchRoute() throws {
        let outcome = try CookleRouteExecutor.execute(
            route: .search(query: "curry"),
            context: context
        )

        switch outcome {
        case .search(let query):
            #expect(query == "curry")
        case .home,
             .diary,
             .recipe,
             .settings,
             .settingsSubscription,
             .settingsLicense:
            Issue.record("Expected .search outcome for search route.")
        }
    }

    @Test("Returns settings subscription outcome for settings subscription route")
    func executeReturnsSettingsSubscriptionOutcome() throws {
        let outcome = try CookleRouteExecutor.execute(
            route: .settingsSubscription,
            context: context
        )

        switch outcome {
        case .settingsSubscription:
            break
        case .home,
             .diary,
             .recipe,
             .search,
             .settings,
             .settingsLicense:
            Issue.record("Expected .settingsSubscription outcome.")
        }
    }
}
