@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

/// Pins the automatic merge that updates matching current data with the file's
/// content, and the matching rules that keep unchanged records out of review.
@MainActor
struct CookleDataImportMergeTests {
    typealias Store = CookleDataImportTestStore

    @Test
    func updating_matches_adds_new_records_updates_matches_and_keeps_unrelated_data() throws {
        let source = Store()
        let fileCurry = try source.recipe("Curry", steps: ["From file"])
        try source.recipe("Soup", steps: ["New"])
        source.diary(day: 1, meals: [.init(recipe: fileCurry, type: .dinner)], note: "File day")
        let archive = try source.archive()

        let target = Store()
        let currentCurry = try target.recipe("Curry", steps: ["Current"])
        let salad = try target.recipe("Salad", steps: ["Unrelated"])
        target.diary(day: 1, meals: [.init(recipe: salad, type: .lunch)], note: "Current day")
        target.diary(day: 2, meals: [.init(recipe: currentCurry, type: .dinner)], note: "Untouched")
        try target.context.save()

        let review = try target.review(of: archive)
        #expect(review.isCurrentDataEmpty == false)
        #expect(review.newRecipeCount == 1)
        #expect(review.recipeConflicts.count == 1)
        #expect(review.diaryConflicts.count == 1)

        let selections = CookleDataImportSelections.updatingMatchingData(for: review)
        #expect(selections.isComplete(for: review))
        let summary = try DataMaintenanceOperations.importArchive(
            archive,
            review: review,
            selections: selections,
            context: target.context
        )

        #expect(summary.addedRecipeCount == 1)
        #expect(summary.updatedRecipeCount == 1)
        #expect(summary.updatedDiaryCount == 1)
        #expect(try target.recipes(named: "Curry").map(\.persistentModelID) == [currentCurry.persistentModelID])
        #expect(currentCurry.steps == ["From file"])
        #expect(salad.steps == ["Unrelated"])
        #expect(try target.recipes(named: "Soup").count == 1)
        let diaries = try target.context.fetch(.diaries(.all)).sorted { lhs, rhs in
            lhs.date < rhs.date
        }
        #expect(diaries.map(\.note) == ["File day", "Untouched"])
        #expect(diaries.first?.objects?.compactMap(\.recipe?.name) == ["Curry"])
    }

    @Test
    func updating_matches_updates_each_current_recipe_at_most_once() throws {
        let source = Store()
        try source.recipe("Curry", steps: ["First file version"])
        try source.recipe("curry", steps: ["Second file version"])
        try source.recipe("CURRY", steps: ["Third file version"])
        let archive = try source.archive()

        let target = Store()
        let older = try target.recipe("Curry", steps: ["Older"])
        let newer = try target.recipe("Curry", steps: ["Newer"])
        try target.context.save()

        let review = try target.review(of: archive)
        #expect(review.recipeConflicts.count == 3)
        let selections = CookleDataImportSelections.updatingMatchingData(for: review)
        let choices = review.recipeConflicts.compactMap { conflict in
            selections.recipeChoices[conflict.id]
        }
        #expect(
            choices == [
                .useBackup(older.persistentModelID),
                .useBackup(newer.persistentModelID),
                .keepBoth
            ]
        )

        let summary = try DataMaintenanceOperations.importArchive(
            archive,
            review: review,
            selections: selections,
            context: target.context
        )
        #expect(summary.updatedRecipeCount == 2)
        #expect(summary.addedRecipeCount == 1)
        #expect(try target.count(Recipe.self) == 3)
    }

    @Test
    func updating_matches_never_replaces_a_recipe_that_another_file_recipe_keeps() throws {
        let source = Store()
        try source.recipe("Curry", steps: ["Same"])
        try source.recipe("Curry", steps: ["Changed"])
        let archive = try source.archive()

        let target = Store()
        let unchanged = try target.recipe("Curry", steps: ["Same"])
        let other = try target.recipe("Curry", steps: ["Other"])
        try target.context.save()

        let review = try target.review(of: archive)
        #expect(review.unchangedRecipeCount == 1)
        let conflict = try #require(review.recipeConflicts.first)
        let selections = CookleDataImportSelections.updatingMatchingData(for: review)
        #expect(selections.recipeChoices[conflict.id] == .useBackup(other.persistentModelID))

        _ = try DataMaintenanceOperations.importArchive(
            archive,
            review: review,
            selections: selections,
            context: target.context
        )
        #expect(unchanged.steps == ["Same"])
        #expect(other.steps == ["Changed"])
    }

    @Test
    func updating_matches_refuses_a_review_made_before_current_data_changed() throws {
        let source = Store()
        try source.recipe("Curry", steps: ["From file"])
        let archive = try source.archive()
        let target = Store()
        try target.recipe("Curry", steps: ["Current"])
        try target.context.save()
        let review = try target.review(of: archive)
        let selections = CookleDataImportSelections.updatingMatchingData(for: review)

        try target.recipe("Curry", steps: ["Added after review"])
        try target.context.save()

        do {
            _ = try DataMaintenanceOperations.importArchive(
                archive,
                review: review,
                selections: selections,
                context: target.context
            )
            Issue.record("Expected the stale review to be refused.")
        } catch CookleDataImportError.reviewChanged(let currentReview) {
            #expect(currentReview.recipeConflicts.first?.candidates.count == 2)
        }
        #expect(try target.recipes(named: "Curry").map(\.steps).sorted { lhs, rhs in
            lhs.joined() < rhs.joined()
        } == [["Added after review"], ["Current"]])
    }

    @Test
    func an_edited_recipe_does_not_turn_its_diary_days_into_conflicts() throws {
        let source = Store()
        let fileCurry = try source.recipe("Curry", steps: ["Old"])
        source.diary(day: 1, meals: [.init(recipe: fileCurry, type: .dinner)], note: "Good")
        source.diary(day: 2, meals: [.init(recipe: fileCurry, type: .lunch)])
        let archive = try source.archive()

        let target = Store()
        let currentCurry = try target.recipe("Curry", steps: ["Edited"])
        target.diary(day: 1, meals: [.init(recipe: currentCurry, type: .dinner)], note: "Good")
        target.diary(day: 2, meals: [.init(recipe: currentCurry, type: .lunch)])
        try target.context.save()

        let review = try target.review(of: archive)
        #expect(review.recipeConflicts.count == 1)
        #expect(review.diaryConflicts.isEmpty)
        #expect(review.unchangedDiaryCount == 2)
    }

    @Test
    func a_diary_day_with_a_different_recipe_name_is_still_a_conflict() throws {
        let source = Store()
        let fileCurry = try source.recipe("Curry")
        source.diary(day: 1, meals: [.init(recipe: fileCurry, type: .dinner)])
        let archive = try source.archive()

        let target = Store()
        let soup = try target.recipe("Soup")
        target.diary(day: 1, meals: [.init(recipe: soup, type: .dinner)])
        try target.context.save()

        #expect(try target.review(of: archive).diaryConflicts.count == 1)
    }

    @Test
    func the_review_reports_whether_current_data_is_empty() throws {
        let source = Store()
        try source.recipe("Curry")
        let archive = try source.archive()

        #expect(try Store().review(of: archive).isCurrentDataEmpty)

        let tagOnly = Store()
        _ = try CookleLibrary.Category.create(context: tagOnly.context, value: "Dinner")
        try tagOnly.context.save()
        #expect(try tagOnly.review(of: archive).isCurrentDataEmpty == false)
    }

    @Test
    func a_recipes_only_file_merges_without_touching_other_data() throws {
        let source = Store()
        try source.recipe("Curry", ingredients: [("Rice", "1 cup")], categories: ["Dinner"])
        let sourceArchive = try source.archive()
        let archive = try partialArchive(
            from: sourceArchive,
            scope: "recipes",
            recipes: sourceArchive.recipes
        )

        let target = Store()
        let salad = try target.recipe("Salad")
        target.diary(day: 1, meals: [.init(recipe: salad, type: .lunch)], note: "Mine")
        try target.context.save()

        let review = try target.review(of: archive)
        #expect(review.newRecipeCount == 1)
        _ = try DataMaintenanceOperations.importArchive(
            archive,
            review: review,
            selections: .init(),
            context: target.context
        )

        #expect(try target.count(Recipe.self) == 2)
        #expect(try target.context.fetch(.diaries(.all)).map(\.note) == ["Mine"])
        #expect(salad.name == "Salad")
    }

    @Test
    func a_diaries_file_brings_the_recipes_its_meals_show() throws {
        let source = Store()
        let curry = try source.recipe("Curry")
        try source.recipe("Unshown")
        source.diary(day: 1, meals: [.init(recipe: curry, type: .dinner)], note: "Shared day")
        let sourceArchive = try source.archive()
        let archive = try partialArchive(
            from: sourceArchive,
            scope: "diaries",
            recipes: sourceArchive.recipes.filter { recipe in
                recipe.name == "Curry"
            },
            diaries: sourceArchive.diaries
        )

        let target = Store()
        try target.recipe("Salad")
        try target.context.save()

        let review = try target.review(of: archive)
        _ = try DataMaintenanceOperations.importArchive(
            archive,
            review: review,
            selections: .init(),
            context: target.context
        )

        #expect(try target.recipes(named: "Curry").count == 1)
        #expect(try target.recipes(named: "Unshown").isEmpty)
        #expect(try target.recipes(named: "Salad").count == 1)
        let diary = try #require(try target.context.fetch(.diaries(.all)).first)
        #expect(diary.objects?.compactMap(\.recipe?.name) == ["Curry"])
    }

    @Test
    func a_partial_file_missing_a_referenced_recipe_is_rejected() throws {
        let source = Store()
        let curry = try source.recipe("Curry")
        source.diary(day: 1, meals: [.init(recipe: curry, type: .dinner)])
        let sourceArchive = try source.archive()

        #expect(throws: CookleDataArchiveService.ArchiveError.self) {
            try partialArchive(
                from: sourceArchive,
                scope: "diaries",
                recipes: [],
                diaries: sourceArchive.diaries
            )
        }
    }
}

private extension CookleDataImportMergeTests {
    /// Writes the chosen records as a partial export package and reads it back,
    /// keeping only the tags and photos those records reference.
    func partialArchive(
        from archive: CookleDataArchive,
        scope: String,
        recipes: [CookleDataArchive.RecipeRecord],
        diaries: [CookleDataArchive.DiaryRecord] = []
    ) throws -> CookleDataArchive {
        let photoIDs = Set(recipes.flatMap { recipe in
            recipe.photos.map(\.photoID)
        })
        let ingredientIDs = Set(recipes.flatMap { recipe in
            recipe.ingredients.map(\.ingredientID)
        })
        let categoryIDs = Set(recipes.flatMap(\.categoryIDs))
        let partial = CookleDataArchive(
            scope: .partial(scope),
            exportedAt: archive.exportedAt,
            ingredients: archive.ingredients.filter { ingredient in
                ingredientIDs.contains(ingredient.id)
            },
            categories: archive.categories.filter { category in
                categoryIDs.contains(category.id)
            },
            photos: archive.photos.filter { photo in
                photoIDs.contains(photo.id)
            },
            recipes: recipes,
            diaries: diaries
        )
        return try CookleDataArchiveService.validatedArchive(
            from: CookleDataArchivePackageTestSupport.unvalidatedPackage(
                from: partial
            ),
            calendar: Store.calendar
        )
    }
}
