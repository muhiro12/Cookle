@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct CookleDataArchiveServiceTests {
    private enum SaveError: Error {
        case forcedFailure
    }

    let context: ModelContext = makeTestContext()

    @Test
    func replaceAll_replaces_current_data_with_archive_contents() async throws {
        let archive = try await makeSampleArchive()
        try insertTemporaryRecipe()

        let summary = try CookleDataArchiveService.replaceAll(
            with: archive,
            context: context
        )

        try assertReplacedSampleData(summary)
    }

    @Test
    func replaceAll_rejects_a_partial_archive_and_keeps_current_data() async throws {
        let archive = try await makeSampleArchive()
        try insertTemporaryRecipe()

        #expect(throws: CookleDataImportError.replacementRequiresCompleteArchive) {
            try CookleDataArchiveService.replaceAll(
                with: CookleDataArchivePackageTestSupport.replacingScope(
                    archive,
                    with: .partial("recipes")
                ),
                context: context
            )
        }
        #expect(context.hasChanges == false)
        #expect(try context.fetch(.recipes(.all)).map(\.name).sorted() == ["Pancakes", "Temporary"])
    }

    @Test
    func validatedArchive_throws_when_recipe_references_missing_photo() {
        let archive = CookleDataArchive(
            scope: .all,
            exportedAt: .now,
            ingredients: [],
            categories: [],
            photos: [],
            recipes: [
                .init(
                    id: "recipe-1",
                    name: "Broken",
                    photos: [
                        .init(
                            photoID: "photo-1",
                            order: TestArchive.brokenPhotoOrder,
                            createdTimestamp: .now,
                            modifiedTimestamp: .now
                        )
                    ],
                    servingSize: TestArchive.brokenServingSize,
                    cookingTime: TestArchive.brokenCookingTime,
                    ingredients: [],
                    steps: [],
                    categoryIDs: [],
                    note: "",
                    createdTimestamp: .now,
                    modifiedTimestamp: .now
                )
            ],
            diaries: []
        )
        let package = try? CookleDataArchivePackageTestSupport.unvalidatedPackage(
            from: archive
        )

        do {
            _ = try CookleDataArchiveService.validatedArchive(
                from: try #require(package)
            )
            Issue.record("Expected archive validation to fail.")
        } catch CookleDataArchiveService.ArchiveError.missingReference(let identifier) {
            #expect(identifier == "photo-1")
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_throws_when_archive_contains_duplicate_identifier() {
        do {
            _ = try CookleDataArchiveService.validatedArchive(
                from: try CookleDataArchivePackageTestSupport.unvalidatedPackage(
                    from: duplicateIngredientIdentifierArchive()
                )
            )
            Issue.record("Expected archive validation to fail.")
        } catch CookleDataArchiveService.ArchiveError.duplicateIdentifier(let identifier) {
            #expect(identifier == TestArchive.duplicateIngredientIdentifier)
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_throws_when_diary_references_missing_recipe() {
        do {
            _ = try CookleDataArchiveService.validatedArchive(
                from: try CookleDataArchivePackageTestSupport.unvalidatedPackage(
                    from: missingDiaryRecipeArchive()
                )
            )
            Issue.record("Expected archive validation to fail.")
        } catch CookleDataArchiveService.ArchiveError.missingReference(let identifier) {
            #expect(identifier == TestArchive.missingRecipeIdentifier)
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func replaceAll_keeps_existing_data_when_archive_is_invalid() throws {
        try insertTemporaryRecipe()

        do {
            _ = try CookleDataArchiveService.replaceAll(
                with: duplicateIngredientIdentifierArchive(),
                context: context
            )
            Issue.record("Expected archive replacement to fail.")
        } catch CookleDataArchiveService.ArchiveError.duplicateIdentifier(let identifier) {
            #expect(identifier == TestArchive.duplicateIngredientIdentifier)
        } catch {
            Issue.record(error)
        }

        let recipes = try context.fetch(.recipes(.all))
        let recipe = try #require(recipes.first)
        #expect(recipes.count == 1)
        #expect(recipe.name == "Temporary")
    }

    @Test
    func replaceAll_rolls_back_pending_replacement_when_save_fails() throws {
        try insertTemporaryRecipe()
        let failingSave: (ModelContext) throws -> Void = { _ in
            throw SaveError.forcedFailure
        }

        do {
            _ = try CookleDataArchiveService.replaceAll(
                with: emptyArchive(),
                context: context,
                save: failingSave
            )
            Issue.record("Expected archive replacement to fail.")
        } catch SaveError.forcedFailure {
            // Expected failure.
        } catch {
            Issue.record(error)
        }

        #expect(context.hasChanges == false)
        let currentRecipes = try context.fetch(.recipes(.all))
        #expect(currentRecipes.map(\.name) == ["Temporary"])

        let freshContext = ModelContext(
            context.container
        )
        let persistedRecipes = try freshContext.fetch(.recipes(.all))
        #expect(persistedRecipes.map(\.name) == ["Temporary"])
    }
}

private extension CookleDataArchiveServiceTests {
    func emptyArchive() -> CookleDataArchive {
        .init(
            scope: .all,
            exportedAt: .now,
            ingredients: [],
            categories: [],
            photos: [],
            recipes: [],
            diaries: []
        )
    }

    func duplicateIngredientIdentifierArchive() -> CookleDataArchive {
        .init(
            scope: .all,
            exportedAt: .now,
            ingredients: [
                ingredientRecord(
                    id: TestArchive.duplicateIngredientIdentifier
                ),
                ingredientRecord(
                    id: TestArchive.duplicateIngredientIdentifier
                )
            ],
            categories: [],
            photos: [],
            recipes: [],
            diaries: []
        )
    }

    func missingDiaryRecipeArchive() -> CookleDataArchive {
        .init(
            scope: .all,
            exportedAt: .now,
            ingredients: [],
            categories: [],
            photos: [],
            recipes: [],
            diaries: [
                .init(
                    id: "diary-1",
                    date: TestArchive.diaryDate,
                    objects: [
                        .init(
                            recipeID: TestArchive.missingRecipeIdentifier,
                            type: .breakfast,
                            order: 1,
                            createdTimestamp: .now,
                            modifiedTimestamp: .now
                        )
                    ],
                    note: "",
                    createdTimestamp: .now,
                    modifiedTimestamp: .now
                )
            ]
        )
    }

    func ingredientRecord(
        id: String
    ) -> CookleDataArchive.IngredientRecord {
        .init(
            id: id,
            value: "Eggs",
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
    }

    func makeSampleArchive() async throws -> CookleDataArchive {
        let category = try Category.create(
            context: context,
            value: "Breakfast"
        )
        let photoObject = try PhotoObject.create(
            context: context,
            photoData: .init(
                data: TestArchive.photoData,
                source: .photosPicker
            ),
            order: TestArchive.photoOrder
        )
        let ingredientObject = try IngredientObject.create(
            context: context,
            ingredient: "Eggs",
            amount: "2",
            order: TestArchive.ingredientOrder
        )
        let recipe = Recipe.create(
            context: context,
            content: .init(
                name: "Pancakes",
                photos: [photoObject],
                servingSize: TestArchive.servingSize,
                cookingTime: TestArchive.cookingTime,
                ingredients: [ingredientObject],
                steps: ["Mix", "Cook"],
                categories: [category],
                note: "Weekend"
            )
        )
        _ = Diary.create(
            context: context,
            content: .init(
                date: TestArchive.diaryDate,
                objects: [
                    DiaryObject.create(context: context, recipe: recipe, type: .breakfast, order: 1)
                ],
                note: "Good"
            )
        )
        try context.save()

        return try CookleDataArchiveService.validatedArchive(
            from: try await CookleDataArchiveService.archivePackage(
                from: context
            )
        )
    }

    func insertTemporaryRecipe() throws {
        _ = Recipe.create(
            context: context,
            content: .init(
                name: "Temporary",
                photos: [],
                servingSize: 1,
                cookingTime: 1,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
        try context.save()
    }

    func assertReplacedSampleData(
        _ summary: CookleDataReplacementSummary
    ) throws {
        let restoredRecipes = try context.fetch(.recipes(.all))
        let restoredRecipe = try #require(restoredRecipes.first)
        let restoredDiaries = try context.fetch(.diaries(.all))
        let restoredDiary = try #require(restoredDiaries.first)

        #expect(summary.recipeCount == 1)
        #expect(summary.diaryCount == 1)
        #expect(summary.categoryCount == 1)
        #expect(summary.ingredientCount == 1)
        #expect(summary.photoCount == 1)
        #expect(restoredRecipes.count == 1)
        #expect(restoredRecipe.name == "Pancakes")
        #expect(restoredRecipe.servingSize == TestArchive.servingSize)
        #expect(restoredRecipe.cookingTime == TestArchive.cookingTime)
        #expect(restoredRecipe.steps == ["Mix", "Cook"])
        #expect(restoredRecipe.note == "Weekend")
        #expect((restoredRecipe.categories ?? []).map(\.value) == ["Breakfast"])
        #expect(restoredRecipe.orderedPhotos.map(\.data) == [TestArchive.photoData])
        #expect((restoredRecipe.ingredientObjects ?? []).first?.ingredient?.value == "Eggs")
        #expect((restoredRecipe.ingredientObjects ?? []).first?.amount == "2")
        #expect(restoredDiaries.count == 1)
        #expect(restoredDiary.note == "Good")
        #expect((restoredDiary.objects ?? []).first?.recipe === restoredRecipe)
        #expect((restoredDiary.objects ?? []).first?.type == .breakfast)
    }
}
