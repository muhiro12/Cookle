import CryptoKit
import Foundation

enum CookleDataArchivePackageCodec {
    private enum PhotoFilename {
        static let firstIndexOffset = 1
        static let indexWidth = 6
        static let minimumDigitASCII: UInt8 = 48
        static let maximumDigitASCII: UInt8 = 57
        static let prefix = "photo-"
        static let suffix = ".data"
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
            packageFormatVersion: CookleDataArchivePackageManifest.currentPackageFormatVersion,
            archiveFormatVersion: archive.formatVersion,
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
        let manifest = try CookleDataArchiveService.decoder.decode(
            CookleDataArchivePackageManifest.self,
            from: package.manifestData
        )
        guard manifest.packageFormatVersion
                == CookleDataArchivePackageManifest.currentPackageFormatVersion else {
            throw CookleDataArchivePackageError.unsupportedPackageFormatVersion(
                manifest.packageFormatVersion
            )
        }
        guard manifest.archiveFormatVersion == CookleDataArchive.currentFormatVersion else {
            throw CookleDataArchiveService.ArchiveError.unsupportedFormatVersion(
                manifest.archiveFormatVersion
            )
        }

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

    static func photoFilename(
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
        return PhotoFilename.prefix + indexText + PhotoFilename.suffix
    }

    static func isPhotoFilename(_ filename: String) -> Bool {
        guard filename.hasPrefix(PhotoFilename.prefix),
              filename.hasSuffix(PhotoFilename.suffix) else {
            return false
        }

        let startIndex = filename.index(
            filename.startIndex,
            offsetBy: PhotoFilename.prefix.count
        )
        let endIndex = filename.index(
            filename.endIndex,
            offsetBy: -PhotoFilename.suffix.count
        )
        let indexText = filename[startIndex ..< endIndex]
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
                at: index
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
            formatVersion: manifest.archiveFormatVersion,
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
