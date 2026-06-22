import SwiftData

extension CookleDataArchiveService {
    static func restoreCategories(
        _ records: [CookleDataArchive.CategoryRecord],
        context: ModelContext
    ) throws -> [String: Category] {
        var categories = [String: Category]()
        for record in records {
            try insert(
                Category.restore(
                    context: context,
                    value: record.value,
                    createdTimestamp: record.createdTimestamp,
                    modifiedTimestamp: record.modifiedTimestamp
                ),
                for: record.id,
                into: &categories
            )
        }
        return categories
    }

    static func restoreIngredients(
        _ records: [CookleDataArchive.IngredientRecord],
        context: ModelContext
    ) throws -> [String: Ingredient] {
        var ingredients = [String: Ingredient]()
        for record in records {
            try insert(
                Ingredient.restore(
                    context: context,
                    value: record.value,
                    createdTimestamp: record.createdTimestamp,
                    modifiedTimestamp: record.modifiedTimestamp
                ),
                for: record.id,
                into: &ingredients
            )
        }
        return ingredients
    }

    static func restorePhotos(
        _ records: [CookleDataArchive.PhotoRecord],
        context: ModelContext
    ) throws -> [String: Photo] {
        var photos = [String: Photo]()
        for record in records {
            try insert(
                Photo.restore(
                    context: context,
                    data: record.data,
                    sourceID: record.sourceID,
                    createdTimestamp: record.createdTimestamp,
                    modifiedTimestamp: record.modifiedTimestamp
                ),
                for: record.id,
                into: &photos
            )
        }
        return photos
    }

    static func restoreRecipes(
        _ records: [CookleDataArchive.RecipeRecord],
        context: ModelContext,
        photos: [String: Photo],
        ingredients: [String: Ingredient],
        categories: [String: Category]
    ) throws -> [String: Recipe] {
        var recipes = [String: Recipe]()
        for record in records {
            try insert(
                try restoredRecipe(
                    from: record,
                    context: context,
                    photos: photos,
                    ingredients: ingredients,
                    categories: categories
                ),
                for: record.id,
                into: &recipes
            )
        }
        return recipes
    }

    static func restoreDiaries(
        _ records: [CookleDataArchive.DiaryRecord],
        context: ModelContext,
        recipes: [String: Recipe]
    ) throws {
        for record in records {
            _ = try restoredDiary(
                from: record,
                context: context,
                recipes: recipes
            )
        }
    }

    static func insert<Value>(
        _ value: Value,
        for identifier: String,
        into dictionary: inout [String: Value]
    ) throws {
        guard dictionary[identifier] == nil else {
            throw ArchiveError.duplicateIdentifier(identifier)
        }
        dictionary[identifier] = value
    }
    static func restoredRecipe(
        from record: CookleDataArchive.RecipeRecord,
        context: ModelContext,
        photos: [String: Photo],
        ingredients: [String: Ingredient],
        categories: [String: Category]
    ) throws -> Recipe {
        try Recipe.restore(
            context: context,
            content: .init(
                name: record.name,
                photos: restoredPhotoObjects(
                    from: record.photos,
                    context: context,
                    photos: photos
                ),
                servingSize: record.servingSize,
                cookingTime: record.cookingTime,
                ingredients: restoredIngredientObjects(
                    from: record.ingredients,
                    context: context,
                    ingredients: ingredients
                ),
                steps: record.steps,
                categories: record.categoryIDs.map { categoryID in
                    guard let category = categories[categoryID] else {
                        throw ArchiveError.missingReference(categoryID)
                    }
                    return category
                },
                note: record.note
            ),
            timestamps: .init(
                created: record.createdTimestamp,
                modified: record.modifiedTimestamp
            )
        )
    }

    static func restoredPhotoObjects(
        from records: [CookleDataArchive.RecipePhotoRecord],
        context: ModelContext,
        photos: [String: Photo]
    ) throws -> [PhotoObject] {
        try records.map { record in
            guard let photo = photos[record.photoID] else {
                throw ArchiveError.missingReference(record.photoID)
            }
            return PhotoObject.restore(
                context: context,
                photo: photo,
                order: record.order,
                createdTimestamp: record.createdTimestamp,
                modifiedTimestamp: record.modifiedTimestamp
            )
        }
    }

    static func restoredIngredientObjects(
        from records: [CookleDataArchive.RecipeIngredientRecord],
        context: ModelContext,
        ingredients: [String: Ingredient]
    ) throws -> [IngredientObject] {
        try records.map { record in
            guard let ingredient = ingredients[record.ingredientID] else {
                throw ArchiveError.missingReference(record.ingredientID)
            }
            return IngredientObject.restore(
                context: context,
                ingredient: ingredient,
                amount: record.amount,
                order: record.order,
                timestamps: .init(
                    created: record.createdTimestamp,
                    modified: record.modifiedTimestamp
                )
            )
        }
    }

    static func restoredDiary(
        from record: CookleDataArchive.DiaryRecord,
        context: ModelContext,
        recipes: [String: Recipe]
    ) throws -> Diary {
        try Diary.restore(
            context: context,
            content: .init(
                date: record.date,
                objects: restoredDiaryObjects(
                    from: record.objects,
                    context: context,
                    recipes: recipes
                ),
                note: record.note
            ),
            timestamps: .init(
                created: record.createdTimestamp,
                modified: record.modifiedTimestamp
            )
        )
    }

    static func restoredDiaryObjects(
        from records: [CookleDataArchive.DiaryObjectRecord],
        context: ModelContext,
        recipes: [String: Recipe]
    ) throws -> [DiaryObject] {
        try records.map { record in
            guard let recipe = recipes[record.recipeID] else {
                throw ArchiveError.missingReference(record.recipeID)
            }
            return DiaryObject.restore(
                context: context,
                recipe: recipe,
                type: record.type,
                order: record.order,
                timestamps: .init(
                    created: record.createdTimestamp,
                    modified: record.modifiedTimestamp
                )
            )
        }
    }
}
