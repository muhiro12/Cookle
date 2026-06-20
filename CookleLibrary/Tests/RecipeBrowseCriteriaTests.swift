@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct RecipeBrowseCriteriaTests {
    @Test
    func browse_withAlphabeticalSort_ordersAscendingAndDescending() {
        let context = makeTestContext()
        let carrotSoup = makeRecipe(
            context: context,
            name: "Carrot Soup"
        )
        let bananaBread = makeRecipe(
            context: context,
            name: "Banana Bread"
        )
        let applePie = makeRecipe(
            context: context,
            name: "Apple Pie"
        )

        let recipes = [
            carrotSoup,
            bananaBread,
            applePie
        ]

        let ascending = RecipeService.browse(
            recipes,
            sortMode: .alphabetical,
            isAscending: true
        )
        let descending = RecipeService.browse(
            recipes,
            sortMode: .alphabetical,
            isAscending: false
        )

        #expect(ascending.map(\.name) == ["Apple Pie", "Banana Bread", "Carrot Soup"])
        #expect(descending.map(\.name) == ["Carrot Soup", "Banana Bread", "Apple Pie"])
    }

    @Test
    func browse_withRecentlyCreatedSort_ordersAscendingAndDescending() {
        let context = makeTestContext()
        let first = makeRecipe(
            context: context,
            name: "First"
        )
        Thread.sleep(forTimeInterval: 0.001)
        let second = makeRecipe(
            context: context,
            name: "Second"
        )
        Thread.sleep(forTimeInterval: 0.001)
        let third = makeRecipe(
            context: context,
            name: "Third"
        )

        let recipes = [
            second,
            third,
            first
        ]

        let ascending = RecipeService.browse(
            recipes,
            sortMode: .recentlyCreated,
            isAscending: true
        )
        let descending = RecipeService.browse(
            recipes,
            sortMode: .recentlyCreated,
            isAscending: false
        )

        #expect(ascending.map(\.name) == ["First", "Second", "Third"])
        #expect(descending.map(\.name) == ["Third", "Second", "First"])
    }

    @Test
    func browse_withMadeCountSort_ordersAscendingAndDescending() {
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

        let recipes = [
            twice,
            thrice,
            once
        ]

        let ascending = RecipeService.browse(
            recipes,
            sortMode: .madeCount,
            isAscending: true
        )
        let descending = RecipeService.browse(
            recipes,
            sortMode: .madeCount,
            isAscending: false
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
    enum TestValues {
        static let cookingTimeMinutes = 10
    }

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
            content: .init(
                name: name,
                photos: [],
                servingSize: 1,
                cookingTime: TestValues.cookingTimeMinutes,
                ingredients: ingredientObjects,
                steps: [],
                categories: categories,
                note: ""
            )
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
            content: .init(
                date: .now,
                objects: objects,
                note: ""
            )
        )
    }
}
