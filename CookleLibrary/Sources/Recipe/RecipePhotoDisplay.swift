import Foundation

/// Shared photo ordering helpers used by app, notifications, and intents.
public enum RecipePhotoDisplay {
    public static func orderedPhotoObjects(
        photoObjects: [PhotoObject]
    ) -> [PhotoObject] {
        photoObjects.sorted()
    }

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

    public static func primaryPhoto(
        photoObjects: [PhotoObject],
        fallbackPhotos: [Photo]
    ) -> Photo? {
        orderedPhotos(
            photoObjects: photoObjects,
            fallbackPhotos: fallbackPhotos
        ).first
    }

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
    var orderedPhotoObjects: [PhotoObject] {
        RecipePhotoDisplay.orderedPhotoObjects(
            photoObjects: photoObjects.orEmpty
        )
    }

    var orderedPhotos: [Photo] {
        RecipePhotoDisplay.orderedPhotos(
            photoObjects: photoObjects.orEmpty,
            fallbackPhotos: photos.orEmpty
        )
    }

    var primaryPhoto: Photo? {
        RecipePhotoDisplay.primaryPhoto(
            photoObjects: photoObjects.orEmpty,
            fallbackPhotos: photos.orEmpty
        )
    }

    var primaryPhotoData: Data? {
        RecipePhotoDisplay.primaryPhotoData(
            photoObjects: photoObjects.orEmpty,
            fallbackPhotos: photos.orEmpty
        )
    }
}
