import Foundation

enum CookleDataArchivePackageValidator {
    typealias ArchiveError = CookleDataArchiveService.ArchiveError
    typealias PackageError = CookleDataArchivePackageError
    typealias ResourceCategory = CookleDataArchiveResourceCategory

    private enum Digest {
        static let hexadecimalCharacterCount = 64
        static let minimumDigitASCII: UInt8 = 48
        static let maximumDigitASCII: UInt8 = 57
        static let minimumLowercaseHexASCII: UInt8 = 97
        static let maximumLowercaseHexASCII: UInt8 = 102
    }

    static func validateManifestData(
        _ data: Data,
        limits: CookleDataArchiveResourceLimits
    ) throws {
        try validateByteCount(
            data.count,
            maximumByteCount: limits.maximumManifestByteCount,
            category: .manifestData
        )
    }

    static func validatedPhotoData(
        package: CookleDataArchivePackage,
        manifest: CookleDataArchivePackageManifest,
        limits: CookleDataArchiveResourceLimits
    ) throws -> [String: Data] {
        try validatePackageResources(
            package: package,
            manifest: manifest,
            limits: limits
        )
        try validateManifestPhotoRecords(
            manifest.photos,
            limits: limits
        )
        let availablePhotoDataByFilename = try photoDataByFilename(
            package.photoFiles
        )
        var remainingFilenames = Set(
            availablePhotoDataByFilename.keys
        )
        var validatedPhotoDataByFilename = [String: Data]()
        validatedPhotoDataByFilename.reserveCapacity(
            manifest.photos.count
        )

        for photo in manifest.photos {
            try Task.checkCancellation()
            guard let data = availablePhotoDataByFilename[photo.filename] else {
                throw PackageError.missingPhotoFile(
                    photo.filename
                )
            }
            guard data.count == photo.byteCount else {
                throw PackageError.photoByteCountMismatch(
                    filename: photo.filename,
                    expectedByteCount: photo.byteCount,
                    actualByteCount: data.count
                )
            }
            guard CookleDataArchivePackageCodec.sha256HexDigest(for: data)
                    == photo.sha256 else {
                throw PackageError.photoDigestMismatch(
                    photo.filename
                )
            }
            remainingFilenames.remove(
                photo.filename
            )
            validatedPhotoDataByFilename[photo.filename] = data
        }

        if let unexpectedFilename = remainingFilenames.min() {
            throw PackageError.unexpectedPhotoFile(
                unexpectedFilename
            )
        }
        return validatedPhotoDataByFilename
    }
}

private extension CookleDataArchivePackageValidator {
    static func validatePackageResources(
        package: CookleDataArchivePackage,
        manifest: CookleDataArchivePackageManifest,
        limits: CookleDataArchiveResourceLimits
    ) throws {
        try validateCount(
            manifest.photos.count,
            maximumCount: limits.maximumTopLevelRecordCountPerCategory,
            category: .photoRecords
        )
        try validateCount(
            package.photoFiles.count,
            maximumCount: limits.maximumTopLevelRecordCountPerCategory,
            category: .photoFiles
        )

        var aggregatePhotoByteCount = 0
        var packageByteCount = package.manifestData.count
        for photoFile in package.photoFiles {
            try Task.checkCancellation()
            try validateByteCount(
                photoFile.data.count,
                maximumByteCount: limits.maximumPhotoByteCount,
                category: .photoData
            )
            try addByteCount(
                photoFile.data.count,
                to: &aggregatePhotoByteCount,
                maximumByteCount: limits.maximumAggregatePhotoByteCount,
                category: .aggregatePhotoData
            )
            try addByteCount(
                photoFile.data.count,
                to: &packageByteCount,
                maximumByteCount: limits.maximumPackageByteCount,
                category: .packageData
            )
        }
        try validateByteCount(
            packageByteCount,
            maximumByteCount: limits.maximumPackageByteCount,
            category: .packageData
        )
    }

    static func validateManifestPhotoRecords(
        _ photos: [CookleDataArchivePackageManifest.PhotoRecord],
        limits: CookleDataArchiveResourceLimits
    ) throws {
        var aggregatePhotoByteCount = 0
        var filenames = Set<String>()
        for (index, photo) in photos.enumerated() {
            try Task.checkCancellation()
            guard filenames.insert(photo.filename).inserted else {
                throw PackageError.duplicatePhotoFilename(
                    photo.filename
                )
            }
            guard photo.filename == CookleDataArchivePackageCodec.photoFilename(at: index) else {
                throw PackageError.invalidPhotoFilename(
                    photo.filename
                )
            }
            guard photo.byteCount >= .zero else {
                throw PackageError.invalidPhotoByteCount(
                    filename: photo.filename,
                    byteCount: photo.byteCount
                )
            }
            try validateByteCount(
                photo.byteCount,
                maximumByteCount: limits.maximumPhotoByteCount,
                category: .photoData
            )
            try addByteCount(
                photo.byteCount,
                to: &aggregatePhotoByteCount,
                maximumByteCount: limits.maximumAggregatePhotoByteCount,
                category: .aggregatePhotoData
            )
            guard isValidDigest(photo.sha256) else {
                throw PackageError.invalidPhotoDigest(
                    photo.filename
                )
            }
        }
    }

    static func photoDataByFilename(
        _ photoFiles: [CookleDataArchivePackage.PhotoFile]
    ) throws -> [String: Data] {
        var result = [String: Data]()
        result.reserveCapacity(
            photoFiles.count
        )
        for photoFile in photoFiles {
            try Task.checkCancellation()
            guard CookleDataArchivePackageCodec.isPhotoFilename(photoFile.filename) else {
                throw PackageError.invalidPhotoFilename(
                    photoFile.filename
                )
            }
            guard result.updateValue(
                photoFile.data,
                forKey: photoFile.filename
            ) == nil else {
                throw PackageError.duplicatePhotoFilename(
                    photoFile.filename
                )
            }
        }
        return result
    }

    static func isValidDigest(
        _ digest: String
    ) -> Bool {
        let bytes = digest.utf8
        guard bytes.count == Digest.hexadecimalCharacterCount else {
            return false
        }
        return bytes.allSatisfy { byte in
            let isDigit = byte >= Digest.minimumDigitASCII
                && byte <= Digest.maximumDigitASCII
            let isLowercaseHex = byte >= Digest.minimumLowercaseHexASCII
                && byte <= Digest.maximumLowercaseHexASCII
            return isDigit || isLowercaseHex
        }
    }

    static func addByteCount(
        _ byteCount: Int,
        to aggregateByteCount: inout Int,
        maximumByteCount: Int,
        category: ResourceCategory
    ) throws {
        let (newByteCount, overflowed) = aggregateByteCount.addingReportingOverflow(
            byteCount
        )
        guard overflowed == false else {
            throw ArchiveError.resourceByteCountExceeded(
                category: category,
                actualByteCount: .max,
                maximumByteCount: maximumByteCount
            )
        }
        try validateByteCount(
            newByteCount,
            maximumByteCount: maximumByteCount,
            category: category
        )
        aggregateByteCount = newByteCount
    }

    static func validateCount(
        _ count: Int,
        maximumCount: Int,
        category: ResourceCategory
    ) throws {
        guard count <= maximumCount else {
            throw ArchiveError.resourceCountExceeded(
                category: category,
                actualCount: count,
                maximumCount: maximumCount
            )
        }
    }

    static func validateByteCount(
        _ byteCount: Int,
        maximumByteCount: Int,
        category: ResourceCategory
    ) throws {
        guard byteCount <= maximumByteCount else {
            throw ArchiveError.resourceByteCountExceeded(
                category: category,
                actualByteCount: byteCount,
                maximumByteCount: maximumByteCount
            )
        }
    }
}
