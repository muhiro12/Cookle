@testable import CookleLibrary
import SwiftData
import Testing

@MainActor
struct TagMergeServiceTests {
    let context: ModelContext = makeTestContext()

    @Test
    func duplicateTags_detects_normalized_ingredient_values() {
        let firstIngredient = Ingredient.restore(
            context: context,
            value: " Eggs ",
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
        let secondIngredient = Ingredient.restore(
            context: context,
            value: "eggs",
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )

        let duplicates = TagService.duplicateTags(
            matching: firstIngredient,
            in: [
                firstIngredient,
                secondIngredient
            ]
        )

        #expect(duplicates.count == 2)
    }

    @Test
    func mergeDuplicateIngredients_reassignsIngredientObjectsAndDeletesChildren() throws {
        let parent = Ingredient.restore(
            context: context,
            value: "Eggs",
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
        let child = Ingredient.restore(
            context: context,
            value: " eggs ",
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
        let parentObject = makeIngredientObject(
            ingredient: parent,
            amount: "1"
        )
        let childObject = makeIngredientObject(
            ingredient: child,
            amount: "2"
        )
        makeRecipe(
            name: "Parent Recipe",
            ingredients: [parentObject]
        )
        makeRecipe(
            name: "Child Recipe",
            ingredients: [childObject]
        )

        let outcome = try TagService.mergeDuplicatesWithOutcome(
            context: context,
            keeping: parent
        )
        try context.save()

        let ingredients = try context.fetch(.ingredients(.all))
        let ingredientObjects = try context.fetch(FetchDescriptor<IngredientObject>())

        #expect(outcome.effects == [.notificationPlanChanged])
        #expect(ingredients.count == 1)
        #expect(ingredientObjects.count == 2)
        #expect(ingredientObjects.allSatisfy { object in
            object.ingredient === parent
        })
    }

    @Test
    func mergeDuplicateCategories_reassignsRecipesAndDeletesChildren() throws {
        let parent = Category.restore(
            context: context,
            value: "Breakfast",
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
        let child = Category.restore(
            context: context,
            value: " breakfast ",
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
        makeRecipe(
            name: "Parent Recipe",
            categories: [parent]
        )
        makeRecipe(
            name: "Child Recipe",
            categories: [child]
        )

        let outcome = try TagService.mergeDuplicatesWithOutcome(
            context: context,
            keeping: parent
        )
        try context.save()

        let categories = try context.fetch(.categories(.all))
        let recipes = try context.fetch(.recipes(.all))

        #expect(outcome.effects == [.notificationPlanChanged])
        #expect(categories.count == 1)
        #expect(recipes.allSatisfy { recipe in
            (recipe.categories ?? []).map(\.persistentModelID) == [
                parent.persistentModelID
            ]
        })
    }

    @Test
    func mergeDuplicateIngredients_preserves_amounts_and_row_order() throws {
        let parent = Ingredient.restore(
            context: context,
            value: "Olive Oil",
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
        let child = Ingredient.restore(
            context: context,
            value: "olive  oil",
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
        makeRecipe(
            name: "Dressing",
            ingredients: [
                makeIngredientObject(ingredient: parent, amount: "1 tbsp", order: 0),
                makeIngredientObject(ingredient: child, amount: "2 tbsp", order: 1)
            ]
        )

        _ = try TagService.mergeDuplicatesWithOutcome(
            context: context,
            keeping: parent
        )
        try context.save()

        let objects = try context.fetch(FetchDescriptor<IngredientObject>())
            .sorted { $0.order < $1.order }

        // Merging changes which Ingredient the rows point at; it must not
        // rewrite the quantities the user typed or reshuffle the rows.
        #expect(objects.map(\.amount) == ["1 tbsp", "2 tbsp"])
        #expect(objects.map(\.order) == [0, 1])
        #expect(objects.allSatisfy { $0.ingredient === parent })
    }

    @Test
    func mergeDuplicates_is_a_no_op_once_the_duplicates_are_gone() throws {
        let parent = Ingredient.restore(
            context: context,
            value: "Eggs",
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
        let child = Ingredient.restore(
            context: context,
            value: " eggs ",
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
        makeRecipe(
            name: "Omelette",
            ingredients: [
                makeIngredientObject(ingredient: parent, amount: "1"),
                makeIngredientObject(ingredient: child, amount: "2")
            ]
        )

        _ = try TagService.mergeDuplicatesWithOutcome(
            context: context,
            keeping: parent
        )
        try context.save()

        // Re-running against an already merged tag must not delete the survivor
        // or disturb the rows that were reassigned to it.
        _ = try TagService.mergeDuplicatesWithOutcome(
            context: context,
            keeping: parent
        )
        try context.save()

        let ingredients = try context.fetch(.ingredients(.all))
        let objects = try context.fetch(FetchDescriptor<IngredientObject>())

        #expect(ingredients.map(\.value) == ["Eggs"])
        #expect(objects.count == 2)
        #expect(objects.allSatisfy { $0.ingredient === parent })
    }
}

private extension TagMergeServiceTests {
    enum TestValues {
        static let servingSize = 1
        static let cookingTimeMinutes = 10
        static let firstOrder = 1
    }

    func makeIngredientObject(
        ingredient: Ingredient,
        amount: String,
        order: Int = TestValues.firstOrder
    ) -> IngredientObject {
        IngredientObject.restore(
            context: context,
            ingredient: ingredient,
            amount: amount,
            order: order,
            timestamps: .init(
                created: .now,
                modified: .now
            )
        )
    }

    @discardableResult
    func makeRecipe(
        name: String,
        ingredients: [IngredientObject] = [],
        categories: [Category] = []
    ) -> Recipe {
        Recipe.create(
            context: context,
            content: .init(
                name: name,
                photos: [],
                servingSize: TestValues.servingSize,
                cookingTime: TestValues.cookingTimeMinutes,
                ingredients: ingredients,
                steps: [],
                categories: categories,
                note: ""
            )
        )
    }
}
