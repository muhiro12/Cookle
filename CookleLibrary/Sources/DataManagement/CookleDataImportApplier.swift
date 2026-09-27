import Foundation
import SwiftData

/// Performs the mutations of an already validated merge import.
///
/// Tags reuse current records with the exact same value, photos reuse a
/// current photo with the same image bytes, and only backup content that the
/// choices keep is inserted, so repeating an import does not duplicate data.
@MainActor
final class CookleDataImportApplier {
    private let archive: CookleDataArchive
    private let review: CookleDataImportReview
    private let selections: CookleDataImportSelections
    private let context: ModelContext
    private let builder: CookleDataImportSnapshotBuilder
    private let photoRecords: [String: CookleDataArchive.PhotoRecord]
    private let ingredientValues: [String: String]
    private let categoryValues: [String: String]

    private var photoIndex = [Data: [Photo]]()
    private var resolvedPhotos = [String: Photo]()
    private var ingredients = [String: Ingredient]()
    private var categories = [String: Category]()
    private var resolvedRecipes = [String: Recipe]()
    private var addedPhotoCount = Int.zero

    init(
        archive: CookleDataArchive,
        review: CookleDataImportReview,
        selections: CookleDataImportSelections,
        context: ModelContext
    ) {
        self.archive = archive
        self.review = review
        self.selections = selections
        self.context = context
        builder = .init(archive: archive)
        photoRecords = Dictionary(
            uniqueKeysWithValues: archive.photos.map { record in
                (record.id, record)
            }
        )
        ingredientValues = Dictionary(
            uniqueKeysWithValues: archive.ingredients.map { record in
                (record.id, record.value)
            }
        )
        categoryValues = Dictionary(
            uniqueKeysWithValues: archive.categories.map { record in
                (record.id, record.value)
            }
        )
    }

    func apply() throws -> CookleDataImportSummary {
        for photo in try context.fetch(.photos(.all)) {
            photoIndex[builder.currentDigest(for: photo), default: []].append(photo)
        }
        let recipeCounts = try applyRecipes()
        let diaryCounts = try applyDiaries()
        try insertStandaloneRecords()
        return .init(
            addedRecipeCount: recipeCounts.added,
            updatedRecipeCount: recipeCounts.updated,
            keptRecipeCount: recipeCounts.kept,
            unchangedRecipeCount: review.unchangedRecipeCount,
            addedDiaryCount: diaryCounts.added,
            updatedDiaryCount: diaryCounts.updated,
            combinedDiaryCount: diaryCounts.combined,
            keptDiaryCount: diaryCounts.kept,
            unchangedDiaryCount: review.unchangedDiaryCount,
            addedPhotoCount: addedPhotoCount
        )
    }
}

private extension CookleDataImportApplier {
    struct RecipeCounts {
        var added = Int.zero
        var updated = Int.zero
        var kept = Int.zero
    }

    struct DiaryCounts {
        var added = Int.zero
        var updated = Int.zero
        var combined = Int.zero
        var kept = Int.zero
    }

    func applyRecipes() throws -> RecipeCounts {
        var counts = RecipeCounts()
        for record in archive.recipes {
            if let target = review.unchangedRecipeTargets[record.id] {
                resolvedRecipes[record.id] = try existingRecipe(target)
                continue
            }
            switch selections.recipeChoices[record.id] {
            case .keepCurrent(let target):
                resolvedRecipes[record.id] = try existingRecipe(target)
                counts.kept += 1
            case .useBackup(let target):
                let recipe = try existingRecipe(target)
                try replaceContent(of: recipe, with: record)
                resolvedRecipes[record.id] = recipe
                counts.updated += 1
            case .keepBoth, nil:
                resolvedRecipes[record.id] = try insertRecipe(record)
                counts.added += 1
            }
        }
        return counts
    }

    func applyDiaries() throws -> DiaryCounts {
        var counts = DiaryCounts()
        let conflicts = Dictionary(
            uniqueKeysWithValues: review.diaryConflicts.map { conflict in
                (conflict.id, conflict)
            }
        )
        for record in archive.diaries where review.unchangedDiaryTargets[record.id] == nil {
            guard let conflict = conflicts[record.id] else {
                _ = Diary.restore(
                    context: context,
                    content: .init(
                        date: record.date,
                        objects: try diaryObjects(from: record.objects),
                        note: record.note
                    ),
                    timestamps: .init(created: record.createdTimestamp, modified: record.modifiedTimestamp)
                )
                counts.added += 1
                continue
            }
            let diary = try existingDiary(conflict.currentDiaryID)
            switch selections.diaryChoices[record.id] {
            case .useBackup:
                try replaceContent(of: diary, with: record)
                counts.updated += 1
            case .combine:
                try combine(record, into: diary)
                counts.combined += 1
            case .keepCurrent, nil:
                counts.kept += 1
            }
        }
        return counts
    }

    /// Adds backup photos and tags that no backup recipe uses, so an import
    /// keeps standalone records without creating unused copies of discarded versions.
    func insertStandaloneRecords() throws {
        let usedPhotoIDs = Set(archive.recipes.flatMap { recipe in
            recipe.photos.map(\.photoID)
        })
        for photo in archive.photos where usedPhotoIDs.contains(photo.id) == false {
            _ = try resolvedPhoto(photo.id)
        }
        let usedIngredientIDs = Set(archive.recipes.flatMap { recipe in
            recipe.ingredients.map(\.ingredientID)
        })
        for ingredient in archive.ingredients where usedIngredientIDs.contains(ingredient.id) == false {
            _ = try resolvedIngredient(ingredient.id)
        }
        let usedCategoryIDs = Set(archive.recipes.flatMap(\.categoryIDs))
        for category in archive.categories where usedCategoryIDs.contains(category.id) == false {
            _ = try resolvedCategory(category.id)
        }
    }

    func insertRecipe(_ record: CookleDataArchive.RecipeRecord) throws -> Recipe {
        Recipe.restore(
            context: context,
            content: try content(of: record),
            timestamps: .init(created: record.createdTimestamp, modified: record.modifiedTimestamp)
        )
    }

    /// Keeps the recipe itself, so diary rows that show it show the backup content.
    func replaceContent(
        of recipe: Recipe,
        with record: CookleDataArchive.RecipeRecord
    ) throws {
        let previousPhotoObjects = recipe.photoObjects ?? []
        let previousIngredientObjects = recipe.ingredientObjects ?? []
        CascadeDeletionSupport.materialize(previousPhotoObjects)
        CascadeDeletionSupport.materialize(previousIngredientObjects)
        recipe.update(content: try content(of: record))
        previousPhotoObjects.forEach(context.delete)
        previousIngredientObjects.forEach(context.delete)
    }

    func content(of record: CookleDataArchive.RecipeRecord) throws -> RecipeContent {
        .init(
            name: record.name,
            photos: try record.photos.map { photo in
                PhotoObject.restore(
                    context: context,
                    photo: try resolvedPhoto(photo.photoID),
                    order: photo.order,
                    createdTimestamp: photo.createdTimestamp,
                    modifiedTimestamp: photo.modifiedTimestamp
                )
            },
            servingSize: record.servingSize,
            cookingTime: record.cookingTime,
            ingredients: try record.ingredients.map { ingredient in
                IngredientObject.restore(
                    context: context,
                    ingredient: try resolvedIngredient(ingredient.ingredientID),
                    amount: ingredient.amount,
                    order: ingredient.order,
                    timestamps: .init(created: ingredient.createdTimestamp, modified: ingredient.modifiedTimestamp)
                )
            },
            steps: record.steps,
            categories: try record.categoryIDs.map(resolvedCategory),
            note: record.note
        )
    }

    /// Replaces only this day's meals and note.
    func replaceContent(
        of diary: Diary,
        with record: CookleDataArchive.DiaryRecord
    ) throws {
        let previousObjects = diary.objects ?? []
        CascadeDeletionSupport.materialize(previousObjects)
        diary.update(
            content: .init(
                date: diary.date,
                objects: try diaryObjects(from: record.objects),
                note: record.note
            )
        )
        previousObjects.forEach(context.delete)
    }

    /// Keeps every current row and adds backup rows beyond the number of
    /// equivalent rows the day already has, so repeats are not collapsed.
    func combine(
        _ record: CookleDataArchive.DiaryRecord,
        into diary: Diary
    ) throws {
        let currentObjects = diary.objects ?? []
        var remainingEquivalents = MealKey.counts(
            currentObjects.compactMap { object in
                guard let type = object.type, let recipe = object.recipe else {
                    return nil
                }
                return .init(type: type, recipeID: recipe.persistentModelID)
            }
        )
        var nextOrder = [DiaryObjectType: Int]()
        for object in currentObjects {
            guard let type = object.type else {
                continue
            }
            nextOrder[type] = max(nextOrder[type] ?? .zero, object.order)
        }
        var addedObjects = [DiaryObject]()
        let backupObjects = record.objects.sorted { lhs, rhs in
            (MealKey.index(of: lhs.type), lhs.order) < (MealKey.index(of: rhs.type), rhs.order)
        }
        for object in backupObjects {
            let recipe = try resolvedRecipe(object.recipeID)
            let key = MealKey(type: object.type, recipeID: recipe.persistentModelID)
            if let remaining = remainingEquivalents[key], remaining > .zero {
                remainingEquivalents[key] = remaining - 1
                continue
            }
            let order = (nextOrder[object.type] ?? .zero) + 1
            nextOrder[object.type] = order
            addedObjects.append(
                DiaryObject.create(context: context, recipe: recipe, type: object.type, order: order)
            )
        }
        diary.update(
            content: .init(
                date: diary.date,
                objects: currentObjects + addedObjects,
                note: CookleDataImportNotes.combined(current: diary.note, backup: record.note)
            )
        )
    }

    func diaryObjects(
        from records: [CookleDataArchive.DiaryObjectRecord]
    ) throws -> [DiaryObject] {
        try records.map { record in
            DiaryObject.restore(
                context: context,
                recipe: try resolvedRecipe(record.recipeID),
                type: record.type,
                order: record.order,
                timestamps: .init(created: record.createdTimestamp, modified: record.modifiedTimestamp)
            )
        }
    }
}

private extension CookleDataImportApplier {
    typealias MealKey = CookleDataImportMealKey
    typealias ArchiveError = CookleDataArchiveService.ArchiveError

    func existingRecipe(_ identifier: PersistentIdentifier) throws -> Recipe {
        guard let recipe = try context.fetchFirst(.recipes(.idIs(identifier))) else {
            throw CookleDataImportError.reviewChanged(review)
        }
        return recipe
    }

    func existingDiary(_ identifier: PersistentIdentifier) throws -> Diary {
        guard let diary = try context.fetchFirst(
            FetchDescriptor<Diary>(
                predicate: #Predicate { diary in
                    diary.persistentModelID == identifier
                }
            )
        ) else {
            throw CookleDataImportError.reviewChanged(review)
        }
        return diary
    }

    func resolvedRecipe(_ recordID: String) throws -> Recipe {
        guard let recipe = resolvedRecipes[recordID] else {
            throw ArchiveError.missingReference(recordID)
        }
        return recipe
    }

    func resolvedPhoto(_ recordID: String) throws -> Photo {
        if let photo = resolvedPhotos[recordID] {
            return photo
        }
        guard let record = photoRecords[recordID],
              let digest = builder.archiveDigest(forPhotoID: recordID) else {
            throw ArchiveError.missingReference(recordID)
        }

        // Reuse only matching bytes and source; neither version loses provenance.
        if let existing = photoIndex[digest]?.first(where: { photo in
            photo.data == record.data && photo.sourceID == record.sourceID
        }) {
            resolvedPhotos[recordID] = existing
            return existing
        }

        let inserted = Photo.restore(
            context: context,
            data: record.data,
            sourceID: record.sourceID,
            createdTimestamp: record.createdTimestamp,
            modifiedTimestamp: record.modifiedTimestamp
        )
        addedPhotoCount += 1
        photoIndex[digest, default: []].append(inserted)
        resolvedPhotos[recordID] = inserted
        return inserted
    }

    func resolvedIngredient(_ recordID: String) throws -> Ingredient {
        guard let value = ingredientValues[recordID] else {
            throw ArchiveError.missingReference(recordID)
        }
        if let ingredient = ingredients[value] {
            return ingredient
        }

        let ingredient = try Ingredient.create(context: context, value: value)
        ingredients[value] = ingredient
        return ingredient
    }

    func resolvedCategory(_ recordID: String) throws -> Category {
        guard let value = categoryValues[recordID] else {
            throw ArchiveError.missingReference(recordID)
        }
        if let category = categories[value] {
            return category
        }

        let category = try Category.create(context: context, value: value)
        categories[value] = category
        return category
    }
}
