import Foundation

struct RecipeFormPhotoRemovalResolver {
    let recipe: Recipe
    let photos: [PhotoData]

    func behavior(for index: Int) -> RecipePhotoRemovalBehavior? {
        guard photos.indices.contains(index),
              let persistedPhotoObject = persistedPhotoObject(
                for: index
              ) else {
            return nil
        }

        return .persistedPhotoBehavior(
            draftReferenceCount: draftReferenceCount(
                for: index
            ),
            persistedReferenceCountOutsideRecipe:
                persistedReferenceCountOutsideRecipe(
                    for: persistedPhotoObject
                )
        )
    }

    func persistedPhotoObject(for index: Int) -> PhotoObject? {
        let photoData = photos[index]
        let matchingPhotoObjects = recipe.orderedPhotoObjects.filter { photoObject in
            guard let photo = photoObject.photo else {
                return false
            }

            return photo.data == photoData.data
                && photo.source == photoData.source
        }
        let matchingDraftCount = photos.prefix(
            index + 1
        )
        .filter { currentPhoto in
            currentPhoto.data == photoData.data
                && currentPhoto.source == photoData.source
        }
        .count

        guard matchingDraftCount <= matchingPhotoObjects.count else {
            return nil
        }

        return matchingPhotoObjects[matchingDraftCount - 1]
    }

    func draftReferenceCount(for index: Int) -> Int {
        let photoData = photos[index]
        return photos.filter { currentPhoto in
            currentPhoto.data == photoData.data
                && currentPhoto.source == photoData.source
        }
        .count
    }

    func persistedReferenceCountOutsideRecipe(
        for photoObject: PhotoObject
    ) -> Int {
        guard let photo = photoObject.photo else {
            return .zero
        }

        let currentRecipeReferenceCount = recipe.orderedPhotoObjects
            .filter { currentPhotoObject in
                guard let currentPhoto = currentPhotoObject.photo else {
                    return false
                }

                return currentPhoto.data == photo.data
                    && currentPhoto.source == photo.source
            }
            .count
        let totalReferenceCount = (photo.objects ?? []).count

        return max(
            .zero,
            totalReferenceCount - currentRecipeReferenceCount
        )
    }
}
