@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct CookleDataArchiveServiceTests {
    let context: ModelContext = makeTestContext()

    @Test
    func restore_replaces_current_data_with_archive_contents() throws {
        let backupData = try makeSampleBackupData()
        try insertTemporaryRecipe()

        let summary = try CookleDataArchiveService.restore(
            CookleDataArchiveService.validatedArchive(
                from: backupData
            ),
            context: context
        )

        try assertRestoredSampleData(summary)
    }

    @Test
    func validatedArchive_throws_when_recipe_references_missing_photo() {
        let archive = CookleDataArchive(
            formatVersion: CookleDataArchive.currentFormatVersion,
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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try? encoder.encode(
            archive
        )

        do {
            _ = try CookleDataArchiveService.validatedArchive(
                from: try #require(data)
            )
            Issue.record("Expected archive validation to fail.")
        } catch CookleDataArchiveService.ArchiveError.missingReference(let identifier) {
            #expect(identifier == "photo-1")
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_throws_when_format_version_is_unsupported() {
        do {
            _ = try CookleDataArchiveService.validatedArchive(
                from: try encodedData(
                    from: unsupportedFormatArchive()
                )
            )
            Issue.record("Expected archive validation to fail.")
        } catch CookleDataArchiveService.ArchiveError.unsupportedFormatVersion(let version) {
            #expect(version == TestArchive.unsupportedFormatVersion)
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_throws_when_archive_contains_duplicate_identifier() {
        do {
            _ = try CookleDataArchiveService.validatedArchive(
                from: try encodedData(
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
                from: try encodedData(
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
    func restore_keeps_existing_data_when_archive_is_invalid() throws {
        try insertTemporaryRecipe()

        do {
            _ = try CookleDataArchiveService.restore(
                unsupportedFormatArchive(),
                context: context
            )
            Issue.record("Expected archive restore to fail.")
        } catch CookleDataArchiveService.ArchiveError.unsupportedFormatVersion(let version) {
            #expect(version == TestArchive.unsupportedFormatVersion)
        } catch {
            Issue.record(error)
        }

        let recipes = try context.fetch(.recipes(.all))
        let recipe = try #require(recipes.first)
        #expect(recipes.count == 1)
        #expect(recipe.name == "Temporary")
    }
}

private extension CookleDataArchiveServiceTests {
    func encodedData(
        from archive: CookleDataArchive
    ) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(
            archive
        )
    }

    func emptyArchive(
        formatVersion: Int = CookleDataArchive.currentFormatVersion
    ) -> CookleDataArchive {
        .init(
            formatVersion: formatVersion,
            exportedAt: .now,
            ingredients: [],
            categories: [],
            photos: [],
            recipes: [],
            diaries: []
        )
    }

    func unsupportedFormatArchive() -> CookleDataArchive {
        emptyArchive(
            formatVersion: TestArchive.unsupportedFormatVersion
        )
    }

    func duplicateIngredientIdentifierArchive() -> CookleDataArchive {
        .init(
            formatVersion: CookleDataArchive.currentFormatVersion,
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
            formatVersion: CookleDataArchive.currentFormatVersion,
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

    func makeSampleBackupData() throws -> Data {
        let category = Category.create(
            context: context,
            value: "Breakfast"
        )
        let photoObject = PhotoObject.create(
            context: context,
            photoData: .init(
                data: TestArchive.photoData,
                source: .photosPicker
            ),
            order: TestArchive.photoOrder
        )
        let ingredientObject = IngredientObject.create(
            context: context,
            ingredient: "Eggs",
            amount: "2",
            order: TestArchive.ingredientOrder
        )
        let recipe = Recipe.create(
            context: context,
            name: "Pancakes",
            photos: [photoObject],
            servingSize: TestArchive.servingSize,
            cookingTime: TestArchive.cookingTime,
            ingredients: [ingredientObject],
            steps: [
                "Mix",
                "Cook"
            ],
            categories: [category],
            note: "Weekend"
        )
        let diaryObject = DiaryObject.create(
            context: context,
            recipe: recipe,
            type: .breakfast,
            order: 1
        )
        _ = Diary.create(
            context: context,
            date: TestArchive.diaryDate,
            objects: [diaryObject],
            note: "Good"
        )
        try context.save()

        return try CookleDataArchiveService.encodedArchive(
            from: context
        )
    }

    func insertTemporaryRecipe() throws {
        _ = Recipe.create(
            context: context,
            name: "Temporary",
            photos: [],
            servingSize: 1,
            cookingTime: 1,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        try context.save()
    }

    func assertRestoredSampleData(
        _ summary: CookleDataRestoreSummary
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
