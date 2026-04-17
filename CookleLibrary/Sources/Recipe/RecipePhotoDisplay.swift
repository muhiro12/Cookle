import Foundation

/// Shared photo ordering helpers used by app, notifications, and intents.
public enum RecipePhotoDisplay {
    /// Returns photo objects sorted by their display order.
    public static func orderedPhotoObjects(
        photoObjects: [PhotoObject]
    ) -> [PhotoObject] {
        photoObjects.sorted()
    }

    /// Returns ordered photos, falling back to flattened photos when needed.
    public static func orderedPhotos(
        photoObjects: [PhotoObject],
        fallbackPhotos: [Photo]
    ) -> [Photo] {
        let orderedPhotos = orderedPhotoObjects(
            photoObjects: photoObjects
        ).compactMap(\.photo)
        if orderedPhotos.isNotEmpty {
            return orderedPhotos
        }
        return fallbackPhotos
    }

    /// Returns the first photo in display order.
    public static func primaryPhoto(
        photoObjects: [PhotoObject],
        fallbackPhotos: [Photo]
    ) -> Photo? {
        orderedPhotos(
            photoObjects: photoObjects,
            fallbackPhotos: fallbackPhotos
        ).first
    }

    /// Returns the data for the first photo in display order.
    public static func primaryPhotoData(
        photoObjects: [PhotoObject],
        fallbackPhotos: [Photo]
    ) -> Data? {
        primaryPhoto(
            photoObjects: photoObjects,
            fallbackPhotos: fallbackPhotos
        )?.data
    }
}

public extension Recipe {
    /// Photo objects sorted by their display order.
    var orderedPhotoObjects: [PhotoObject] {
        RecipePhotoDisplay.orderedPhotoObjects(
            photoObjects: photoObjects.orEmpty
        )
    }

    /// Photos sorted for display, with legacy fallback when needed.
    var orderedPhotos: [Photo] {
        RecipePhotoDisplay.orderedPhotos(
            photoObjects: photoObjects.orEmpty,
            fallbackPhotos: photos.orEmpty
        )
    }

    /// The first photo that should be shown for this recipe.
    var primaryPhoto: Photo? {
        RecipePhotoDisplay.primaryPhoto(
            photoObjects: photoObjects.orEmpty,
            fallbackPhotos: photos.orEmpty
        )
    }

    /// The data for the first photo that should be shown for this recipe.
    var primaryPhotoData: Data? {
        RecipePhotoDisplay.primaryPhotoData(
            photoObjects: photoObjects.orEmpty,
            fallbackPhotos: photos.orEmpty
        )
    }
}
