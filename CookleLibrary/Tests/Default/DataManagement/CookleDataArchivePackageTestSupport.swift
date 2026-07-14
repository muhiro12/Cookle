@testable import CookleLibrary
import Foundation

enum CookleDataArchivePackageTestSupport {
    private enum Value {
        static let exportedAtTimeInterval: TimeInterval = 1_700_000_000
        static let secondPhotoByte: UInt8 = 2
        static let thirdPhotoByte: UInt8 = 3
        static let fourthPhotoByte: UInt8 = 4
        static let servingSize = 2
        static let cookingTime = 15
    }

    static let exportedAt = Date(
        timeIntervalSince1970: Value.exportedAtTimeInterval
    )
    static let photoData = Data([
        1,
        Value.secondPhotoByte,
        Value.thirdPhotoByte,
        Value.fourthPhotoByte
    ])

    static var calendar: Calendar {
        var result = Calendar(
            identifier: .gregorian
        )
        result.timeZone = TimeZone(
            secondsFromGMT: .zero
        ) ?? .current
        return result
    }

    static var legacyArchiveData: Data {
        Data(
            #"""
                {
                "formatVersion": 1,
                "exportedAt": "2023-11-14T22:13:20Z",
                "ingredients": [],
                "categories": [],
                "photos": [
                {
                "id": "photo-1",
                "data": "AQIDBA==",
                "sourceID": "photos-picker",
                "createdTimestamp": "2023-11-14T22:13:20Z",
                "modifiedTimestamp": "2023-11-14T22:13:20Z"
                }
                ],
                "recipes": [],
                "diaries": []
                }
            """#.utf8
        )
    }

    static func archive(
        photoPayloads: [Data] = [photoData]
    ) -> CookleDataArchive {
        let photos = photoPayloads.enumerated().map { index, data in
            CookleDataArchive.PhotoRecord(
                id: "photo-\(index + 1)",
                data: data,
                sourceID: "photos-picker",
                createdTimestamp: exportedAt,
                modifiedTimestamp: exportedAt
            )
        }
        let recipePhotos = photos.enumerated().map { index, photo in
            CookleDataArchive.RecipePhotoRecord(
                photoID: photo.id,
                order: index,
                createdTimestamp: exportedAt,
                modifiedTimestamp: exportedAt
            )
        }
        return .init(
            formatVersion: CookleDataArchive.currentFormatVersion,
            exportedAt: exportedAt,
            ingredients: [ingredientRecord()],
            categories: [categoryRecord()],
            photos: photos,
            recipes: [recipeRecord(photos: recipePhotos)],
            diaries: [diaryRecord()]
        )
    }

    static func package(
        photoPayloads: [Data] = [photoData],
        limits: CookleDataArchiveResourceLimits = ArchiveResourceLimitTestSupport.makeLimits()
    ) throws -> CookleDataArchivePackage {
        try CookleDataArchivePackageCodec.package(
            from: archive(
                photoPayloads: photoPayloads
            ),
            calendar: calendar,
            limits: limits
        )
    }

    static func manifest(
        from package: CookleDataArchivePackage
    ) throws -> CookleDataArchivePackageManifest {
        try CookleDataArchiveService.decoder.decode(
            CookleDataArchivePackageManifest.self,
            from: package.manifestData
        )
    }

    static func package(
        manifest: CookleDataArchivePackageManifest,
        photoFiles: [CookleDataArchivePackage.PhotoFile]
    ) throws -> CookleDataArchivePackage {
        .init(
            manifestData: try CookleDataArchiveService.encoder.encode(
                manifest
            ),
            photoFiles: photoFiles
        )
    }

    static func replacingPackageFormatVersion(
        _ manifest: CookleDataArchivePackageManifest,
        with packageFormatVersion: Int
    ) -> CookleDataArchivePackageManifest {
        .init(
            packageFormatVersion: packageFormatVersion,
            archiveFormatVersion: manifest.archiveFormatVersion,
            exportedAt: manifest.exportedAt,
            ingredients: manifest.ingredients,
            categories: manifest.categories,
            photos: manifest.photos,
            recipes: manifest.recipes,
            diaries: manifest.diaries
        )
    }

    static func replacingPhotos(
        _ manifest: CookleDataArchivePackageManifest,
        with photos: [CookleDataArchivePackageManifest.PhotoRecord]
    ) -> CookleDataArchivePackageManifest {
        .init(
            packageFormatVersion: manifest.packageFormatVersion,
            archiveFormatVersion: manifest.archiveFormatVersion,
            exportedAt: manifest.exportedAt,
            ingredients: manifest.ingredients,
            categories: manifest.categories,
            photos: photos,
            recipes: manifest.recipes,
            diaries: manifest.diaries
        )
    }
}

private extension CookleDataArchivePackageTestSupport {
    static func ingredientRecord() -> CookleDataArchive.IngredientRecord {
        .init(
            id: "ingredient-1",
            value: "Eggs",
            createdTimestamp: exportedAt,
            modifiedTimestamp: exportedAt
        )
    }

    static func categoryRecord() -> CookleDataArchive.CategoryRecord {
        .init(
            id: "category-1",
            value: "Breakfast",
            createdTimestamp: exportedAt,
            modifiedTimestamp: exportedAt
        )
    }

    static func recipeRecord(
        photos: [CookleDataArchive.RecipePhotoRecord]
    ) -> CookleDataArchive.RecipeRecord {
        .init(
            id: "recipe-1",
            name: "Pancakes",
            photos: photos,
            servingSize: Value.servingSize,
            cookingTime: Value.cookingTime,
            ingredients: [
                .init(
                    ingredientID: "ingredient-1",
                    amount: "2",
                    order: .zero,
                    createdTimestamp: exportedAt,
                    modifiedTimestamp: exportedAt
                )
            ],
            steps: [
                "Mix",
                "Cook"
            ],
            categoryIDs: [
                "category-1"
            ],
            note: "Weekend",
            createdTimestamp: exportedAt,
            modifiedTimestamp: exportedAt
        )
    }

    static func diaryRecord() -> CookleDataArchive.DiaryRecord {
        .init(
            id: "diary-1",
            date: exportedAt,
            objects: [
                .init(
                    recipeID: "recipe-1",
                    type: .breakfast,
                    order: .zero,
                    createdTimestamp: exportedAt,
                    modifiedTimestamp: exportedAt
                )
            ],
            note: "Good",
            createdTimestamp: exportedAt,
            modifiedTimestamp: exportedAt
        )
    }
}
