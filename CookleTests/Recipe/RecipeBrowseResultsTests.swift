import CookleLibrary
import Foundation
import SwiftData
import Testing

@testable import Cookle

@MainActor
struct RecipeBrowseResultsTests {
    @Test
    func alphabetical_sortsAscendingAndDescending() throws {
        let context = try makeCookleTestContext()
        let apple = makeRecipe(
            context: context,
            name: "Apple Pie"
        )
        let banana = makeRecipe(
            context: context,
            name: "Banana Bread"
        )
        let carrot = makeRecipe(
            context: context,
            name: "Carrot Soup"
        )

        let ascending = RecipeBrowseResults.recipes(
            from: [carrot, banana, apple],
            criteria: .init(
                searchText: "",
                selectedCategory: nil,
                selectedIngredient: nil,
                photosOnly: false,
                sortMode: .alphabetical,
                isAscending: true
            )
        )
        let descending = RecipeBrowseResults.recipes(
            from: [apple, banana, carrot],
            criteria: .init(
                searchText: "",
                selectedCategory: nil,
                selectedIngredient: nil,
                photosOnly: false,
                sortMode: .alphabetical,
                isAscending: false
            )
        )

        #expect(ascending.map(\.name) == ["Apple Pie", "Banana Bread", "Carrot Soup"])
        #expect(descending.map(\.name) == ["Carrot Soup", "Banana Bread", "Apple Pie"])
    }

    @Test
    func recentlyCreated_sortsAscendingAndDescending() throws {
        let context = try makeCookleTestContext()
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

        let ascending = RecipeBrowseResults.recipes(
            from: [third, first, second],
            criteria: .init(
                searchText: "",
                selectedCategory: nil,
                selectedIngredient: nil,
                photosOnly: false,
                sortMode: .recentlyCreated,
                isAscending: true
            )
        )
        let descending = RecipeBrowseResults.recipes(
            from: [first, third, second],
            criteria: .init(
                searchText: "",
                selectedCategory: nil,
                selectedIngredient: nil,
                photosOnly: false,
                sortMode: .recentlyCreated,
                isAscending: false
            )
        )

        #expect(ascending.map(\.name) == ["First", "Second", "Third"])
        #expect(descending.map(\.name) == ["Third", "Second", "First"])
    }

    @Test
    func madeCount_sortsAscendingAndDescending() throws {
        let context = try makeCookleTestContext()
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

        let ascending = RecipeBrowseResults.recipes(
            from: [twice, thrice, once],
            criteria: .init(
                searchText: "",
                selectedCategory: nil,
                selectedIngredient: nil,
                photosOnly: false,
                sortMode: .madeCount,
                isAscending: true
            )
        )
        let descending = RecipeBrowseResults.recipes(
            from: [once, twice, thrice],
            criteria: .init(
                searchText: "",
                selectedCategory: nil,
                selectedIngredient: nil,
                photosOnly: false,
                sortMode: .madeCount,
                isAscending: false
            )
        )

        #expect(ascending.map(\.name) == ["Once", "Twice", "Thrice"])
        #expect(descending.map(\.name) == ["Thrice", "Twice", "Once"])
    }

    @Test
    func filters_applyAndSemanticsForCategoryIngredientAndPhotos() throws {
        let context = try makeCookleTestContext()
        let dinner = Category.create(
            context: context,
            value: "Dinner"
        )
        let breakfast = Category.create(
            context: context,
            value: "Breakfast"
        )
        let egg = Ingredient.create(
            context: context,
            value: "Egg"
        )

        let matchingRecipe = makeRecipe(
            context: context,
            name: "Carbonara",
            categories: [dinner],
            ingredients: ["Egg"],
            photoCount: 1
        )
        let noPhotoRecipe = makeRecipe(
            context: context,
            name: "Omelet",
            categories: [dinner],
            ingredients: ["Egg"]
        )
        let wrongCategoryRecipe = makeRecipe(
            context: context,
            name: "Breakfast Bowl",
            categories: [breakfast],
            ingredients: ["Egg"],
            photoCount: 1
        )

        let result = RecipeBrowseResults.recipes(
            from: [matchingRecipe, noPhotoRecipe, wrongCategoryRecipe],
            criteria: .init(
                searchText: "",
                selectedCategory: dinner,
                selectedIngredient: egg,
                photosOnly: true,
                sortMode: .alphabetical,
                isAscending: true
            )
        )

        #expect(result.map(\.name) == ["Carbonara"])
    }

    @Test
    func search_matchesRecipeNameOnly() throws {
        let context = try makeCookleTestContext()
        let nameMatch = makeRecipe(
            context: context,
            name: "Apple Pie",
            ingredients: ["Flour"]
        )
        let ingredientOnlyMatch = makeRecipe(
            context: context,
            name: "Soup",
            ingredients: ["Apple"]
        )

        let result = RecipeBrowseResults.recipes(
            from: [ingredientOnlyMatch, nameMatch],
            criteria: .init(
                searchText: "Apple",
                selectedCategory: nil,
                selectedIngredient: nil,
                photosOnly: false,
                sortMode: .alphabetical,
                isAscending: true
            )
        )

        #expect(result.map(\.name) == ["Apple Pie"])
    }
}

private extension RecipeBrowseResultsTests {
    func makeRecipe(
        context: ModelContext,
        name: String,
        categories: [CookleLibrary.Category] = [],
        ingredients: [String] = [],
        photoCount: Int = 0
    ) -> Recipe {
        let defaultServingSize = 1
        let defaultCookingTime = 10

        let ingredientObjects = ingredients.enumerated().map { index, ingredient in
            IngredientObject.create(
                context: context,
                ingredient: ingredient,
                amount: "",
                order: index + 1
            )
        }
        let photos = (0..<photoCount).map { index in
            PhotoObject.create(
                context: context,
                photoData: .init(
                    data: Data("\(name)-\(index)".utf8),
                    source: .photosPicker
                ),
                order: index + 1
            )
        }

        return Recipe.create(
            context: context,
            name: name,
            photos: photos,
            servingSize: defaultServingSize,
            cookingTime: defaultCookingTime,
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
