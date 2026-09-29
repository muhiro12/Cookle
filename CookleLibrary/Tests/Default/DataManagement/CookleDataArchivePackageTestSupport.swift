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
            scope: .all,
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

    /// Returns `manifest` with any of its header fields replaced.
    static func replacingHeader(
        _ manifest: CookleDataArchivePackageManifest,
        format: String? = nil,
        formatVersion: Int? = nil,
        schemaVersion: String? = nil,
        scope: String? = nil
    ) -> CookleDataArchivePackageManifest {
        .init(
            format: format ?? manifest.format,
            formatVersion: formatVersion ?? manifest.formatVersion,
            schemaVersion: schemaVersion ?? manifest.schemaVersion,
            contents: .init(
                scope: scope ?? manifest.contents.scope
            ),
            exportedAt: manifest.exportedAt,
            ingredients: manifest.ingredients,
            categories: manifest.categories,
            photos: manifest.photos,
            recipes: manifest.recipes,
            diaries: manifest.diaries
        )
    }

    /// Writes `archive` as a current export package without validating it, so
    /// tests can hand invalid content to the reader.
    static func unvalidatedPackage(
        from archive: CookleDataArchive
    ) throws -> CookleDataArchivePackage {
        let photoFiles = archive.photos.enumerated().map { index, photo in
            CookleDataArchivePackage.PhotoFile(
                filename: CookleDataArchivePackageCodec.photoFilename(
                    at: index,
                    fileExtension: CookleDataArchivePackageCodec.photoFileExtension(
                        for: photo.data
                    )
                ),
                data: photo.data
            )
        }
        let manifest = CookleDataArchivePackageManifest(
            format: CookleDataArchivePackageManifest.formatIdentifier,
            formatVersion: CookleDataArchivePackageManifest.currentFormatVersion,
            schemaVersion: CookleDataArchiveSchemaVersions.string(
                for: CookleDataArchiveSchemaVersions.current
            ),
            contents: .init(
                scope: archive.scope.rawValue
            ),
            exportedAt: archive.exportedAt,
            ingredients: archive.ingredients,
            categories: archive.categories,
            photos: zip(archive.photos, photoFiles).map { photo, file in
                .init(
                    id: photo.id,
                    filename: file.filename,
                    byteCount: photo.data.count,
                    sha256: CookleDataArchivePackageCodec.sha256HexDigest(
                        for: photo.data
                    ),
                    sourceID: photo.sourceID,
                    createdTimestamp: photo.createdTimestamp,
                    modifiedTimestamp: photo.modifiedTimestamp
                )
            },
            recipes: archive.recipes,
            diaries: archive.diaries
        )
        return try package(
            manifest: manifest,
            photoFiles: photoFiles
        )
    }

    /// Returns `archive` with a different scope and otherwise the same content.
    static func replacingScope(
        _ archive: CookleDataArchive,
        with scope: CookleDataArchiveScope
    ) -> CookleDataArchive {
        .init(
            scope: scope,
            exportedAt: archive.exportedAt,
            ingredients: archive.ingredients,
            categories: archive.categories,
            photos: archive.photos,
            recipes: archive.recipes,
            diaries: archive.diaries
        )
    }

    static func replacingPhotos(
        _ manifest: CookleDataArchivePackageManifest,
        with photos: [CookleDataArchivePackageManifest.PhotoRecord]
    ) -> CookleDataArchivePackageManifest {
        .init(
            format: manifest.format,
            formatVersion: manifest.formatVersion,
            schemaVersion: manifest.schemaVersion,
            contents: manifest.contents,
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
