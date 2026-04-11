import SwiftData

enum RecipePhotoMutation {
    static func remove(
        context: ModelContext,
        recipe: Recipe,
        photoObject: PhotoObject
    ) {
        let removedPhoto = photoObject.photo
        let shouldDeletePhoto = removedPhoto?.objects.orEmpty.count == 1
        let remainingPhotoObjects = recipe.photoObjects.orEmpty.filter { object in
            object.persistentModelID != photoObject.persistentModelID
        }

        context.delete(photoObject)
        recipe.update(
            name: recipe.name,
            photos: remainingPhotoObjects,
            servingSize: recipe.servingSize,
            cookingTime: recipe.cookingTime,
            ingredients: recipe.ingredientObjects.orEmpty,
            steps: recipe.steps,
            categories: recipe.categories.orEmpty,
            note: recipe.note
        )

        if shouldDeletePhoto,
           let removedPhoto {
            context.delete(removedPhoto)
        }
    }
}
