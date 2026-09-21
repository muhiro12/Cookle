@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

// A widget keeps the recipe it was configured with, by identifier, in its own
// process. When that recipe is deleted in the app, the widget's next timeline
// build resolves the identifier against a store that no longer holds it.
//
// `RecipeProvider` relies on that resolution returning nil so it can fall back
// to its "Recipe Unavailable" title instead of rendering a stale entry. The
// existing codec tests cover a *malformed* identifier; these cover the case the
// widget actually meets — a perfectly valid identifier whose record is gone.
@MainActor
struct WidgetStaleSelectionTests {
    @Test
    func a_deleted_selection_resolves_to_nil_not_an_error() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let recipe = makeRecipe(context: context, name: "Curry")
            try context.save()

            let identifier = RecipeStableIdentifierCodec.stableIdentifier(for: recipe)
            #expect(
                try RecipeStableIdentifierCodec.recipe(
                    from: identifier,
                    context: context
                ) != nil
            )

            _ = RecipeOperations.deleteWithOutcome(context: context, recipe: recipe)
            try context.save()

            // Reopened the way the widget process would.
            let widgetContext = try makeContext(at: url)
            #expect(
                try RecipeStableIdentifierCodec.recipe(
                    from: identifier,
                    context: widgetContext
                ) == nil
            )
        }
    }

    @Test
    func a_deleted_last_opened_recipe_resolves_to_nil() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let recipe = makeRecipe(context: context, name: "Curry")
            try context.save()
            let identifier = RecipeStableIdentifierCodec.stableIdentifier(for: recipe)

            #expect(
                try RecipeService.lastOpenedRecipe(
                    context: context,
                    lastOpenedRecipeID: identifier
                ) != nil
            )

            _ = RecipeOperations.deleteWithOutcome(context: context, recipe: recipe)
            try context.save()

            // The preference still holds the identifier after the delete, so
            // the nil has to come from the lookup rather than from the absence
            // of a stored value.
            let widgetContext = try makeContext(at: url)
            #expect(
                try RecipeService.lastOpenedRecipe(
                    context: widgetContext,
                    lastOpenedRecipeID: identifier
                ) == nil
            )
        }
    }

    @Test
    func latest_and_random_resolve_to_nil_on_an_emptied_store() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let recipe = makeRecipe(context: context, name: "Curry")
            try context.save()

            #expect(try RecipeOperations.latestRecipe(context: context) != nil)
            #expect(try RecipeOperations.randomRecipe(context: context) != nil)

            _ = RecipeOperations.deleteWithOutcome(context: context, recipe: recipe)
            try context.save()

            let widgetContext = try makeContext(at: url)
            #expect(try RecipeOperations.latestRecipe(context: widgetContext) == nil)
            #expect(try RecipeOperations.randomRecipe(context: widgetContext) == nil)
        }
    }

    @Test
    func a_surviving_recipe_is_still_reachable_after_a_sibling_is_deleted() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let kept = makeRecipe(context: context, name: "Curry")
            let removed = makeRecipe(context: context, name: "Salad")
            try context.save()
            let keptIdentifier = RecipeStableIdentifierCodec.stableIdentifier(for: kept)

            _ = RecipeOperations.deleteWithOutcome(context: context, recipe: removed)
            try context.save()

            // Without this the tests above would pass against a lookup that
            // had simply stopped resolving anything.
            let widgetContext = try makeContext(at: url)
            let resolved = try RecipeStableIdentifierCodec.recipe(
                from: keptIdentifier,
                context: widgetContext
            )
            #expect(resolved?.name == "Curry")
        }
    }
}

private extension WidgetStaleSelectionTests {
    enum Value {
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

    func makeRecipe(context: ModelContext, name: String) -> Recipe {
        Recipe.create(
            context: context,
            content: .init(
                name: name,
                photos: [],
                servingSize: Value.servingSize,
                cookingTime: Value.cookingTimeMinutes,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
    }
}
