@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct RecipeBrowseCriteriaTests {
    @Test
    func search_withAlphabeticalSort_ordersAscendingAndDescending() throws {
        let context = makeTestContext()
        _ = makeRecipe(
            context: context,
            name: "Carrot Soup"
        )
        _ = makeRecipe(
            context: context,
            name: "Banana Bread"
        )
        _ = makeRecipe(
            context: context,
            name: "Apple Pie"
        )

        let ascending = try RecipeService.search(
            context: context,
            criteria: .init(
                searchText: "",
                sortMode: .alphabetical,
                isAscending: true
            )
        )
        let descending = try RecipeService.search(
            context: context,
            criteria: .init(
                searchText: "",
                sortMode: .alphabetical,
                isAscending: false
            )
        )

        #expect(ascending.map(\.name) == ["Apple Pie", "Banana Bread", "Carrot Soup"])
        #expect(descending.map(\.name) == ["Carrot Soup", "Banana Bread", "Apple Pie"])
    }

    @Test
    func search_withRecentlyCreatedSort_ordersAscendingAndDescending() throws {
        let context = makeTestContext()
        _ = makeRecipe(
            context: context,
            name: "First"
        )
        Thread.sleep(forTimeInterval: 0.001)
        _ = makeRecipe(
            context: context,
            name: "Second"
        )
        Thread.sleep(forTimeInterval: 0.001)
        _ = makeRecipe(
            context: context,
            name: "Third"
        )

        let ascending = try RecipeService.search(
            context: context,
            criteria: .init(
                searchText: "",
                sortMode: .recentlyCreated,
                isAscending: true
            )
        )
        let descending = try RecipeService.search(
            context: context,
            criteria: .init(
                searchText: "",
                sortMode: .recentlyCreated,
                isAscending: false
            )
        )

        #expect(ascending.map(\.name) == ["First", "Second", "Third"])
        #expect(descending.map(\.name) == ["Third", "Second", "First"])
    }

    @Test
    func search_withMadeCountSort_ordersAscendingAndDescending() throws {
        let context = makeTestContext()
        let once = makeRecipe(
            context: context,
            name: "Once"
        )
        let twice = makeRecipe(
            context: context,
            name: "Twice"
        )
        let thrice = makeRecipe(
            context: context,
            name: "Thrice"
        )

        [
            (once, 1),
            (twice, 2),
            (thrice, 3)
        ].forEach { recipe, count in
            attachDiaryObjects(
                to: recipe,
                count: count,
                context: context
            )
        }

        let ascending = try RecipeService.search(
            context: context,
            criteria: .init(
                searchText: "",
                sortMode: .madeCount,
                isAscending: true
            )
        )
        let descending = try RecipeService.search(
            context: context,
            criteria: .init(
                searchText: "",
                sortMode: .madeCount,
                isAscending: false
            )
        )

        #expect(ascending.map(\.name) == ["Once", "Twice", "Thrice"])
        #expect(descending.map(\.name) == ["Thrice", "Twice", "Once"])
    }

    @Test
    func search_withCriteria_usesCanonicalAnyTextMatchesSemantics() throws {
        let context = makeTestContext()
        let breakfast = Category.create(
            context: context,
            value: "Breakfast"
        )
        _ = makeRecipe(
            context: context,
            name: "Apple Pie",
            ingredients: ["Flour"]
        )
        _ = makeRecipe(
            context: context,
            name: "Soup",
            ingredients: ["Apple"]
        )
        _ = makeRecipe(
            context: context,
            name: "Toast",
            categories: [breakfast]
        )

        let ingredientMatches = try RecipeService.search(
            context: context,
            criteria: .init(
                searchText: "Apple",
                sortMode: .alphabetical,
                isAscending: true
            )
        )
        let categoryMatches = try RecipeService.search(
            context: context,
            criteria: .init(
                searchText: "Breakfast",
                sortMode: .alphabetical,
                isAscending: true
            )
        )

        #expect(ingredientMatches.map(\.name) == ["Apple Pie", "Soup"])
        #expect(categoryMatches.map(\.name) == ["Toast"])
    }
}

private extension RecipeBrowseCriteriaTests {
    func makeRecipe(
        context: ModelContext,
        name: String,
        categories: [CookleLibrary.Category] = [],
        ingredients: [String] = []
    ) -> Recipe {
        let ingredientObjects = ingredients.enumerated().map { index, ingredient in
            IngredientObject.create(
                context: context,
                ingredient: ingredient,
                amount: "",
                order: index + 1
            )
        }

        return Recipe.create(
            context: context,
            name: name,
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: ingredientObjects,
            steps: [],
            categories: categories,
            note: ""
        )
    }

    func attachDiaryObjects(
        to recipe: Recipe,
        count: Int,
        context: ModelContext
    ) {
        let objects = (0..<count).map { index in
            DiaryObject.create(
                context: context,
                recipe: recipe,
                type: .breakfast,
                order: index + 1
            )
        }

        _ = Diary.create(
            context: context,
            date: .now,
            objects: objects,
            note: ""
        )
    }
}
