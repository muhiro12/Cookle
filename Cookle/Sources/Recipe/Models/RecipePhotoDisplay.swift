import Foundation

enum RecipePhotoDisplay {
    nonisolated static func orderedPhotoObjects(
        photoObjects: [PhotoObject]
    ) -> [PhotoObject] {
        photoObjects.sorted()
    }

    nonisolated static func orderedPhotos(
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

    nonisolated static func primaryPhoto(
        photoObjects: [PhotoObject],
        fallbackPhotos: [Photo]
    ) -> Photo? {
        orderedPhotos(
            photoObjects: photoObjects,
            fallbackPhotos: fallbackPhotos
        ).first
    }

    nonisolated static func primaryPhotoData(
        photoObjects: [PhotoObject],
        fallbackPhotos: [Photo]
    ) -> Data? {
        primaryPhoto(
            photoObjects: photoObjects,
            fallbackPhotos: fallbackPhotos
        )?.data
    }
}

nonisolated extension Recipe {
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
