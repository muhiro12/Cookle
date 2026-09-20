@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

/// Pins what a tag merge leaves behind once the store is involved.
///
/// `TagMergeServiceTests` proves the in-memory reassignment. These tests use a
/// real on-disk store instead, because the questions that matter to a user —
/// does the merge survive a relaunch, what happens when another editor touches
/// the duplicate first, and what is left after a save that never lands — are
/// only answerable across contexts and reopens.
@MainActor
struct TagMergePersistenceTests {
    @Test
    func merge_survives_a_store_reopen_with_amounts_and_order_intact() throws {
        try withDiskStore { url in
            let writer = try makeContext(at: url)
            let parent = makeIngredient(context: writer, value: "Olive Oil")
            let child = makeIngredient(context: writer, value: "olive  oil")
            makeRecipe(
                context: writer,
                name: "Dressing",
                ingredients: [
                    makeIngredientObject(context: writer, ingredient: parent, amount: "1 tbsp", order: 1),
                    makeIngredientObject(context: writer, ingredient: child, amount: "2 tbsp", order: 2)
                ]
            )
            try writer.save()

            _ = try TagOperations.mergeDuplicatesWithOutcome(
                context: writer,
                keeping: parent
            )
            try writer.save()

            // Everything below is read from a context that never saw the merge.
            let reopened = try makeContext(at: url)
            let ingredients = try reopened.fetch(.ingredients(.all))
            let objects = try reopened.fetch(FetchDescriptor<IngredientObject>())
                .sorted { $0.order < $1.order }
            let recipe = try #require(try reopened.fetch(.recipes(.all)).first)

            #expect(ingredients.map(\.value) == ["Olive Oil"])
            #expect(objects.map(\.amount) == ["1 tbsp", "2 tbsp"])
            #expect(objects.map(\.order) == [1, 2])
            #expect(objects.allSatisfy { $0.ingredient?.value == "Olive Oil" })
            #expect((recipe.ingredients ?? []).map(\.value) == ["Olive Oil"])
        }
    }

    @Test
    func merge_keeps_a_row_another_context_attached_to_the_duplicate() throws {
        try withDiskStore { url in
            let writer = try makeContext(at: url)
            let parent = makeIngredient(context: writer, value: "Eggs")
            let child = makeIngredient(context: writer, value: "eggs")
            makeRecipe(
                context: writer,
                name: "Omelette",
                ingredients: [
                    makeIngredientObject(context: writer, ingredient: parent, amount: "2", order: 1)
                ]
            )
            try writer.save()

            // Another editor adds a recipe that uses the duplicate, after the
            // merge preview was built but before the merge is applied.
            let other = try makeContext(at: url)
            let otherChild = try #require(
                try other.fetch(.ingredients(.valueIs("eggs"))).first
            )
            makeRecipe(
                context: other,
                name: "Custard",
                ingredients: [
                    makeIngredientObject(context: other, ingredient: otherChild, amount: "3", order: 1)
                ]
            )
            try other.save()

            let merger = try makeContext(at: url)
            let survivor = try #require(
                try merger.fetch(.ingredients(.valueIs("Eggs"))).first
            )
            _ = try TagOperations.mergeDuplicatesWithOutcome(
                context: merger,
                keeping: survivor
            )
            try merger.save()

            let reopened = try makeContext(at: url)
            let ingredients = try reopened.fetch(.ingredients(.all))
            let objects = try reopened.fetch(FetchDescriptor<IngredientObject>())
            let recipes = try reopened.fetch(.recipes(.all))

            // The duplicate is gone, and neither recipe lost its ingredient row
            // even though one of them was written by a context the merge never
            // saw. `mergeDuplicatesWithOutcome` fetches at apply time rather
            // than reusing what the preview collected, which is what makes the
            // late row reachable.
            #expect(ingredients.map(\.value) == ["Eggs"])
            #expect(recipes.count == 2)
            #expect(objects.count == 2)
            #expect(objects.map(\.amount).sorted() == ["2", "3"])
            #expect(objects.allSatisfy { $0.ingredient?.value == "Eggs" })
            #expect(objects.allSatisfy { $0.recipe != nil })
        }
    }

    @Test
    func category_merge_survives_a_store_reopen_and_keeps_every_recipe() throws {
        try withDiskStore { url in
            let writer = try makeContext(at: url)
            let parent = makeCategory(context: writer, value: "Dinner")
            let child = makeCategory(context: writer, value: "dinner")
            let bothRecipe = makeRecipe(context: writer, name: "Curry", ingredients: [])
            bothRecipe.updateCategories([parent, child])
            let childOnlyRecipe = makeRecipe(context: writer, name: "Stew", ingredients: [])
            childOnlyRecipe.updateCategories([child])
            try writer.save()

            _ = try TagOperations.mergeDuplicatesWithOutcome(
                context: writer,
                keeping: parent
            )
            try writer.save()

            let reopened = try makeContext(at: url)
            let categories = try reopened.fetch(.categories(.all))
            let recipes = try reopened.fetch(.recipes(.all))
                .sorted { $0.name < $1.name }
            let survivor = try #require(categories.first)

            // A recipe that carried both tags must end with one, not a
            // duplicated entry, and a recipe that carried only the child must
            // still be categorized at all.
            #expect(categories.map(\.value) == ["Dinner"])
            #expect(recipes.map(\.name) == ["Curry", "Stew"])
            #expect(recipes.allSatisfy { ($0.categories ?? []).map(\.value) == ["Dinner"] })
            #expect((survivor.recipes ?? []).count == 2)
        }
    }

    @Test
    func category_merge_absorbs_a_recipe_another_context_categorized_late() throws {
        try withDiskStore { url in
            let writer = try makeContext(at: url)
            let parent = makeCategory(context: writer, value: "Dessert")
            let child = makeCategory(context: writer, value: "dessert")
            let firstRecipe = makeRecipe(context: writer, name: "Pudding", ingredients: [])
            firstRecipe.updateCategories([parent])
            _ = child
            try writer.save()

            // Another editor tags a new recipe with the duplicate before the
            // merge is applied.
            let other = try makeContext(at: url)
            let otherChild = try #require(
                try other.fetch(.categories(.valueIs("dessert"))).first
            )
            let lateRecipe = makeRecipe(context: other, name: "Sorbet", ingredients: [])
            lateRecipe.updateCategories([otherChild])
            try other.save()

            let merger = try makeContext(at: url)
            let survivor = try #require(
                try merger.fetch(.categories(.valueIs("Dessert"))).first
            )
            _ = try TagOperations.mergeDuplicatesWithOutcome(
                context: merger,
                keeping: survivor
            )
            try merger.save()

            let reopened = try makeContext(at: url)
            let categories = try reopened.fetch(.categories(.all))
            let recipes = try reopened.fetch(.recipes(.all))
                .sorted { $0.name < $1.name }

            #expect(categories.map(\.value) == ["Dessert"])
            #expect(recipes.map(\.name) == ["Pudding", "Sorbet"])
            #expect(recipes.allSatisfy { ($0.categories ?? []).map(\.value) == ["Dessert"] })
        }
    }

    @Test
    func merge_abandoned_by_a_rollback_leaves_both_tags_in_the_store() throws {
        try withDiskStore { url in
            let writer = try makeContext(at: url)
            let parent = makeIngredient(context: writer, value: "Sugar")
            let child = makeIngredient(context: writer, value: "sugar")
            makeRecipe(
                context: writer,
                name: "Cookies",
                ingredients: [
                    makeIngredientObject(context: writer, ingredient: parent, amount: "100g", order: 1),
                    makeIngredientObject(context: writer, ingredient: child, amount: "50g", order: 2)
                ]
            )
            try writer.save()

            _ = try TagOperations.mergeDuplicatesWithOutcome(
                context: writer,
                keeping: parent
            )
            // The save never lands; the merge is discarded the way a failed
            // mutation discards its pending changes.
            writer.rollback()

            let reopened = try makeContext(at: url)
            let ingredients = try reopened.fetch(.ingredients(.all))
                .map(\.value)
                .sorted()
            let objects = try reopened.fetch(FetchDescriptor<IngredientObject>())
                .sorted { $0.order < $1.order }

            #expect(ingredients == ["Sugar", "sugar"])
            #expect(objects.map(\.amount) == ["100g", "50g"])
            #expect(objects.map { $0.ingredient?.value } == ["Sugar", "sugar"])
        }
    }
}

private extension TagMergePersistenceTests {
    enum TestValues {
        static let servingSize = 1
        static let cookingTimeMinutes = 10
    }

    func withDiskStore(_ body: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        try body(directory.appendingPathComponent("store.sqlite"))
    }

    func makeContext(at url: URL) throws -> ModelContext {
        let container = try ModelContainerFactory.makeModelContainer(
            url: url,
            cloudKitDatabase: .none
        )
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    func makeIngredient(context: ModelContext, value: String) -> Ingredient {
        Ingredient.restore(
            context: context,
            value: value,
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
    }

    func makeCategory(context: ModelContext, value: String) -> CookleSchemaV1.Category {
        CookleSchemaV1.Category.restore(
            context: context,
            value: value,
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
    }

    func makeIngredientObject(
        context: ModelContext,
        ingredient: Ingredient,
        amount: String,
        order: Int
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
        context: ModelContext,
        name: String,
        ingredients: [IngredientObject]
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
                categories: [],
                note: ""
            )
        )
    }
}
