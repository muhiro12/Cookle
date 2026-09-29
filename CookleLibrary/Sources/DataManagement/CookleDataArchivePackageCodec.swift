import CryptoKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum CookleDataArchivePackageCodec {
    typealias Manifest = CookleDataArchivePackageManifest
    typealias SchemaVersions = CookleDataArchiveSchemaVersions

    private enum PhotoFilename {
        static let firstIndexOffset = 1
        static let indexWidth = 6
        static let minimumDigitASCII: UInt8 = 48
        static let maximumDigitASCII: UInt8 = 57
        static let prefix = "photo-"
        static let extensionSeparator: Character = "."
        /// Used when the bytes are not a recognized image type.
        static let fallbackExtension = "data"
        static let allowedExtensions: Set<String> = [
            "bmp",
            fallbackExtension,
            "gif",
            "heic",
            "heif",
            "jpeg",
            "png",
            "tiff",
            "webp"
        ]
    }

    private enum Digest {
        static let encodedCharactersPerByte = 2
        static let highNibbleShift = 4
        static let lowNibbleMask: UInt8 = 0x0F
    }

    static func package(
        from archive: CookleDataArchive,
        calendar: Calendar,
        limits: CookleDataArchiveResourceLimits
    ) throws -> CookleDataArchivePackage {
        try Task.checkCancellation()
        try CookleDataArchiveService.validate(
            archive,
            calendar: calendar,
            limits: limits
        )

        let contents = try packageContents(
            from: archive.photos
        )
        let manifest: CookleDataArchivePackageManifest = .init(
            format: Manifest.formatIdentifier,
            formatVersion: Manifest.currentFormatVersion,
            schemaVersion: SchemaVersions.string(
                for: SchemaVersions.current
            ),
            contents: .init(
                scope: archive.scope.rawValue
            ),
            exportedAt: archive.exportedAt,
            ingredients: archive.ingredients,
            categories: archive.categories,
            photos: contents.manifestPhotos,
            recipes: archive.recipes,
            diaries: archive.diaries
        )
        let package: CookleDataArchivePackage = .init(
            manifestData: try CookleDataArchiveService.encoder.encode(
                manifest
            ),
            photoFiles: contents.photoFiles
        )

        _ = try validatedArchive(
            from: package,
            calendar: calendar,
            limits: limits
        )
        return package
    }

    static func validatedArchive(
        from package: CookleDataArchivePackage,
        calendar: Calendar,
        limits: CookleDataArchiveResourceLimits
    ) throws -> CookleDataArchive {
        try Task.checkCancellation()
        try CookleDataArchivePackageValidator.validateManifestData(
            package.manifestData,
            limits: limits
        )
        try validateHeader(
            try CookleDataArchiveService.decoder.decode(
                Manifest.Header.self,
                from: package.manifestData
            )
        )
        let manifest = try CookleDataArchiveService.decoder.decode(
            Manifest.self,
            from: package.manifestData
        )

        let photoDataByFilename = try CookleDataArchivePackageValidator.validatedPhotoData(
            package: package,
            manifest: manifest,
            limits: limits
        )
        let archive = try archive(
            from: manifest,
            photoDataByFilename: photoDataByFilename
        )
        try CookleDataArchiveService.validate(
            archive,
            calendar: calendar,
            limits: limits
        )
        return archive
    }

    /// Name of the photo at `index` in manifest order, such as `photo-000001.jpeg`.
    static func photoFilename(
        at index: Int,
        fileExtension: String
    ) -> String {
        photoFilenameStem(at: index)
            + String(PhotoFilename.extensionSeparator)
            + fileExtension
    }

    /// Filename extension that describes the image type of `data`.
    static func photoFileExtension(
        for data: Data
    ) -> String {
        guard let source = CGImageSourceCreateWithData(
            data as CFData,
            nil
        ),
        let typeIdentifier = CGImageSourceGetType(source),
        let fileExtension = UTType(typeIdentifier as String)?.preferredFilenameExtension,
        PhotoFilename.allowedExtensions.contains(fileExtension) else {
            return PhotoFilename.fallbackExtension
        }
        return fileExtension
    }

    /// Indicates whether `filename` is a well-formed photo filename, and, when
    /// `index` is given, whether it names the photo at that manifest position.
    static func isPhotoFilename(
        _ filename: String,
        at index: Int? = nil
    ) -> Bool {
        guard let separatorIndex = filename.lastIndex(
            of: PhotoFilename.extensionSeparator
        ) else {
            return false
        }

        let stem = filename[..<separatorIndex]
        let fileExtension = filename[filename.index(after: separatorIndex)...]
        guard PhotoFilename.allowedExtensions.contains(String(fileExtension)),
              stem.hasPrefix(PhotoFilename.prefix) else {
            return false
        }
        if let index {
            return stem == photoFilenameStem(at: index)
        }

        let indexText = stem.dropFirst(PhotoFilename.prefix.count)
        guard indexText.count == PhotoFilename.indexWidth else {
            return false
        }
        return indexText.utf8.allSatisfy { byte in
            byte >= PhotoFilename.minimumDigitASCII
                && byte <= PhotoFilename.maximumDigitASCII
        } && indexText != "000000"
    }

    static func sha256HexDigest(
        for data: Data
    ) -> String {
        let hexadecimalDigits = Array("0123456789abcdef".utf8)
        let digestBytes = Array(
            SHA256.hash(
                data: data
            )
        )
        var resultBytes = [UInt8]()
        resultBytes.reserveCapacity(
            digestBytes.count * Digest.encodedCharactersPerByte
        )
        for byte in digestBytes {
            resultBytes.append(
                hexadecimalDigits[Int(byte >> Digest.highNibbleShift)]
            )
            resultBytes.append(
                hexadecimalDigits[Int(byte & Digest.lowNibbleMask)]
            )
        }
        guard let result = String(
            bytes: resultBytes,
            encoding: .utf8
        ) else {
            preconditionFailure("Hexadecimal digest bytes must be valid UTF-8.")
        }
        return result
    }
}

private extension CookleDataArchivePackageCodec {
    static func validateHeader(
        _ header: Manifest.Header
    ) throws {
        guard header.format == Manifest.formatIdentifier else {
            throw CookleDataArchivePackageError.unsupportedFormat(
                header.format
            )
        }
        guard header.formatVersion == Manifest.currentFormatVersion else {
            throw CookleDataArchivePackageError.unsupportedFormatVersion(
                header.formatVersion
            )
        }
        guard let version = SchemaVersions.version(
            from: header.schemaVersion
        ) else {
            throw CookleDataArchivePackageError.unsupportedSchemaVersion(
                header.schemaVersion
            )
        }
        guard version <= SchemaVersions.current else {
            throw CookleDataArchiveVersionError.newerSchemaVersion(
                header.schemaVersion
            )
        }
        guard SchemaVersions.readable.contains(version) else {
            throw CookleDataArchivePackageError.unsupportedSchemaVersion(
                header.schemaVersion
            )
        }
    }

    static func photoFilenameStem(
        at index: Int
    ) -> String {
        let ordinal = index + PhotoFilename.firstIndexOffset
        let indexText = String(
            repeating: "0",
            count: max(
                PhotoFilename.indexWidth - String(ordinal).count,
                .zero
            )
        ) + String(ordinal)
        return PhotoFilename.prefix + indexText
    }

    static func packageContents(
        from photos: [CookleDataArchive.PhotoRecord]
    ) throws -> (
        manifestPhotos: [CookleDataArchivePackageManifest.PhotoRecord],
        photoFiles: [CookleDataArchivePackage.PhotoFile]
    ) {
        var manifestPhotos = [CookleDataArchivePackageManifest.PhotoRecord]()
        var photoFiles = [CookleDataArchivePackage.PhotoFile]()
        manifestPhotos.reserveCapacity(photos.count)
        photoFiles.reserveCapacity(photos.count)

        for (index, photo) in photos.enumerated() {
            try Task.checkCancellation()
            let filename = photoFilename(
                at: index,
                fileExtension: photoFileExtension(
                    for: photo.data
                )
            )
            manifestPhotos.append(
                .init(
                    id: photo.id,
                    filename: filename,
                    byteCount: photo.data.count,
                    sha256: sha256HexDigest(
                        for: photo.data
                    ),
                    sourceID: photo.sourceID,
                    createdTimestamp: photo.createdTimestamp,
                    modifiedTimestamp: photo.modifiedTimestamp
                )
            )
            photoFiles.append(
                .init(
                    filename: filename,
                    data: photo.data
                )
            )
        }
        return (
            manifestPhotos,
            photoFiles
        )
    }

    static func archive(
        from manifest: CookleDataArchivePackageManifest,
        photoDataByFilename: [String: Data]
    ) throws -> CookleDataArchive {
        .init(
            scope: .init(
                rawValue: manifest.contents.scope
            ),
            exportedAt: manifest.exportedAt,
            ingredients: manifest.ingredients,
            categories: manifest.categories,
            photos: try manifest.photos.map { photo in
                guard let data = photoDataByFilename[photo.filename] else {
                    throw CookleDataArchivePackageError.missingPhotoFile(
                        photo.filename
                    )
                }
                return .init(
                    id: photo.id,
                    data: data,
                    sourceID: photo.sourceID,
                    createdTimestamp: photo.createdTimestamp,
                    modifiedTimestamp: photo.modifiedTimestamp
                )
            },
            recipes: manifest.recipes,
            diaries: manifest.diaries
        )
    }
}
