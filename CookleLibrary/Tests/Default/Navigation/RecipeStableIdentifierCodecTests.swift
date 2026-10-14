@testable import CookleLibrary
import SwiftData
import Testing

@MainActor
struct RecipeStableIdentifierCodecTests {
    let context: ModelContext = makeTestContext()

    @Test
    func encode_and_decode_round_trip_recipe_identifier() throws {
        let recipe = Recipe.create(
            context: context,
            content: .init(
                name: "Soup",
                photos: [],
                servingSize: 2,
                cookingTime: 20,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )

        let encodedIdentifier = try RecipeStableIdentifierCodec.encode(
            recipe.id
        )
        let decodedIdentifier = try RecipeStableIdentifierCodec.decode(
            encodedIdentifier
        )

        #expect(decodedIdentifier == recipe.id)
    }

    @Test
    func stableIdentifier_isDeterministic_forTheSameRecipe() {
        let recipe = Recipe.create(
            context: context,
            content: .init(
                name: "Stew",
                photos: [],
                servingSize: 2,
                cookingTime: 25,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )

        let firstIdentifier = RecipeStableIdentifierCodec.stableIdentifier(
            for: recipe
        )
        let secondIdentifier = RecipeStableIdentifierCodec.stableIdentifier(
            for: recipe
        )

        #expect(firstIdentifier == secondIdentifier)
    }

    @Test
    func recipe_lookup_resolves_existing_recipe() throws {
        let recipe = Recipe.create(
            context: context,
            content: .init(
                name: "Curry",
                photos: [],
                servingSize: 3,
                cookingTime: 30,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )

        let stableIdentifier = RecipeStableIdentifierCodec.stableIdentifier(
            for: recipe
        )
        let resolvedRecipe = try RecipeStableIdentifierCodec.recipe(
            from: stableIdentifier,
            context: context
        )

        #expect(resolvedRecipe === recipe)
    }

    @Test
    func recipe_lookup_returns_nil_for_invalid_identifier() throws {
        let resolvedRecipe = try RecipeStableIdentifierCodec.recipe(
            from: "invalid-id",
            context: context
        )
        #expect(resolvedRecipe == nil)
    }

    @Test
    func saved_identifiers_distinguish_same_named_recipes_after_edits_and_deletion() throws {
        let first = Recipe.create(context: context, content: .init(name: "Same name", note: "First"))
        let second = Recipe.create(context: context, content: .init(name: "Same name", note: "Second"))
        try context.save()
        let firstID = RecipeStableIdentifierCodec.stableIdentifier(for: first)
        let secondID = RecipeStableIdentifierCodec.stableIdentifier(for: second)
        #expect(firstID != secondID)

        first.update(content: .init(name: "Changed name", note: "Edited"))
        try context.save()
        #expect(RecipeStableIdentifierCodec.stableIdentifier(for: first) == firstID)
        #expect(try RecipeStableIdentifierCodec.recipe(from: firstID, context: context)?.note == "Edited")
        #expect(try RecipeStableIdentifierCodec.recipe(from: secondID, context: context)?.note == "Second")

        context.delete(first)
        try context.save()
        #expect(try RecipeStableIdentifierCodec.recipe(from: firstID, context: context) == nil)
        #expect(try RecipeStableIdentifierCodec.recipe(from: secondID, context: context) === second)
    }

    @Test
    func a_reopened_store_resolves_each_same_named_recipe_by_its_original_identifier() throws {
        let directory = try persistentTestDirectory(fileManager: .default)
        let url = directory.appendingPathComponent("recipes.store")
        let identifiers: [String]
        do {
            let writer = ModelContext(try ModelContainerFactory.makeModelContainer(url: url))
            let first = Recipe.create(context: writer, content: .init(name: "Same name", note: "First"))
            let second = Recipe.create(context: writer, content: .init(name: "Same name", note: "Second"))
            try writer.save()
            identifiers = [first, second].map(RecipeStableIdentifierCodec.stableIdentifier(for:))
        }
        let reader = ModelContext(try ModelContainerFactory.makeReadOnlyContainer(url: url))
        let notes = try identifiers.map { identifier in
            try RecipeStableIdentifierCodec.recipe(from: identifier, context: reader)?.note
        }
        #expect(notes == ["First", "Second"])
    }

    @Test
    func an_identifier_from_another_store_never_resolves_to_a_local_namesake() throws {
        let other = makeTestContext()
        let foreign = Recipe.create(context: other, content: .init(name: "Same name"))
        let local = Recipe.create(context: context, content: .init(name: "Same name"))
        try other.save()
        try context.save()
        let foreignID = RecipeStableIdentifierCodec.stableIdentifier(for: foreign)
        #expect(try RecipeStableIdentifierCodec.recipe(from: foreignID, context: context) == nil)
        #expect(try RecipeStableIdentifierCodec.recipe(
            from: RecipeStableIdentifierCodec.stableIdentifier(for: local), context: context
        ) === local)
    }
}
