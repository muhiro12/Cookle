import SwiftData

extension CookleDataArchiveService {
    static func ingredientRecords(
        _ ingredients: [Ingredient],
        identifiers: [PersistentIdentifier: String]
    ) -> [CookleDataArchive.IngredientRecord] {
        ingredients.compactMap { ingredient in
            guard let id = identifier(
                for: ingredient,
                in: identifiers
            ) else {
                return nil
            }
            return .init(
                id: id,
                value: ingredient.value,
                createdTimestamp: ingredient.createdTimestamp,
                modifiedTimestamp: ingredient.modifiedTimestamp
            )
        }
    }

    static func categoryRecords(
        _ categories: [Category],
        identifiers: [PersistentIdentifier: String]
    ) -> [CookleDataArchive.CategoryRecord] {
        categories.compactMap { category in
            guard let id = identifier(
                for: category,
                in: identifiers
            ) else {
                return nil
            }
            return .init(
                id: id,
                value: category.value,
                createdTimestamp: category.createdTimestamp,
                modifiedTimestamp: category.modifiedTimestamp
            )
        }
    }

    static func photoRecords(
        _ photos: [Photo],
        identifiers: [PersistentIdentifier: String]
    ) -> [CookleDataArchive.PhotoRecord] {
        photos.compactMap { photo in
            guard let id = identifier(
                for: photo,
                in: identifiers
            ) else {
                return nil
            }
            return .init(
                id: id,
                data: photo.data,
                sourceID: photo.sourceID,
                createdTimestamp: photo.createdTimestamp,
                modifiedTimestamp: photo.modifiedTimestamp
            )
        }
    }

    static func recipeRecords(
        _ recipes: [Recipe],
        recipeIDs: [PersistentIdentifier: String],
        photoIDs: [PersistentIdentifier: String],
        ingredientIDs: [PersistentIdentifier: String],
        categoryIDs: [PersistentIdentifier: String]
    ) -> [CookleDataArchive.RecipeRecord] {
        recipes.compactMap { recipe in
            guard let id = identifier(
                for: recipe,
                in: recipeIDs
            ) else {
                return nil
            }
            return .init(
                id: id,
                name: recipe.name,
                photos: recipePhotoRecords(
                    (recipe.photoObjects ?? []).sorted(),
                    photoIDs: photoIDs
                ),
                servingSize: recipe.servingSize,
                cookingTime: recipe.cookingTime,
                ingredients: recipeIngredientRecords(
                    (recipe.ingredientObjects ?? []).sorted(),
                    ingredientIDs: ingredientIDs
                ),
                steps: recipe.steps,
                categoryIDs: (recipe.categories ?? []).compactMap { category in
                    identifier(
                        for: category,
                        in: categoryIDs
                    )
                },
                note: recipe.note,
                createdTimestamp: recipe.createdTimestamp,
                modifiedTimestamp: recipe.modifiedTimestamp
            )
        }
    }

    static func recipePhotoRecords(
        _ photoObjects: [PhotoObject],
        photoIDs: [PersistentIdentifier: String]
    ) -> [CookleDataArchive.RecipePhotoRecord] {
        photoObjects.compactMap { object in
            guard let photo = object.photo,
                  let photoID = identifier(
                    for: photo,
                    in: photoIDs
                  ) else {
                return nil
            }
            return .init(
                photoID: photoID,
                order: object.order,
                createdTimestamp: object.createdTimestamp,
                modifiedTimestamp: object.modifiedTimestamp
            )
        }
    }

    static func recipeIngredientRecords(
        _ ingredientObjects: [IngredientObject],
        ingredientIDs: [PersistentIdentifier: String]
    ) -> [CookleDataArchive.RecipeIngredientRecord] {
        ingredientObjects.compactMap { object in
            guard let ingredient = object.ingredient,
                  let ingredientID = identifier(
                    for: ingredient,
                    in: ingredientIDs
                  ) else {
                return nil
            }
            return .init(
                ingredientID: ingredientID,
                amount: object.amount,
                order: object.order,
                createdTimestamp: object.createdTimestamp,
                modifiedTimestamp: object.modifiedTimestamp
            )
        }
    }

    static func diaryRecords(
        _ diaries: [Diary],
        identifiers: [PersistentIdentifier: String],
        recipeIDs: [PersistentIdentifier: String]
    ) -> [CookleDataArchive.DiaryRecord] {
        diaries.compactMap { diary in
            guard let id = identifier(
                for: diary,
                in: identifiers
            ) else {
                return nil
            }
            return .init(
                id: id,
                date: diary.date,
                objects: diaryObjectRecords(
                    (diary.objects ?? []).sorted(),
                    recipeIDs: recipeIDs
                ),
                note: diary.note,
                createdTimestamp: diary.createdTimestamp,
                modifiedTimestamp: diary.modifiedTimestamp
            )
        }
    }

    static func diaryObjectRecords(
        _ objects: [DiaryObject],
        recipeIDs: [PersistentIdentifier: String]
    ) -> [CookleDataArchive.DiaryObjectRecord] {
        objects.compactMap { object in
            guard let recipe = object.recipe,
                  let recipeID = identifier(
                    for: recipe,
                    in: recipeIDs
                  ),
                  let type = object.type else {
                return nil
            }
            return .init(
                recipeID: recipeID,
                type: type,
                order: object.order,
                createdTimestamp: object.createdTimestamp,
                modifiedTimestamp: object.modifiedTimestamp
            )
        }
    }
}
