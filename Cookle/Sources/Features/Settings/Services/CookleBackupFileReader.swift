import Foundation

nonisolated enum CookleBackupFileReader {
    private enum Read {
        static let chunkKibibytes = 64
        static let bytesPerKibibyte = 1_024
        static let chunkByteCount = chunkKibibytes * bytesPerKibibyte
        static let requiredPackageRootEntryCount = 2
    }

    enum Failure: LocalizedError {
        case invalidBackupFile
        case invalidBackupPackage
        case invalidBackupContents
        case cannotAccessBackup
        case backupFileTooLarge
        case tooManyPhotoFiles

        var errorDescription: String? {
            switch self {
            case .invalidBackupFile:
                String(
                    localized: "Select a Cookle backup package or a legacy JSON backup."
                )
            case .invalidBackupPackage:
                String(
                    localized: "The selected Cookle backup package has an invalid file structure."
                )
            case .invalidBackupContents:
                String(
                    localized: "The selected backup is invalid, damaged, or not supported by this version of Cookle."
                )
            case .cannotAccessBackup:
                String(
                    localized: "Cookle couldn’t access the selected backup. Choose it again and try again."
                )
            case .backupFileTooLarge:
                String(
                    localized: "The selected backup exceeds Cookle’s safe import size limit."
                )
            case .tooManyPhotoFiles:
                String(
                    localized: "The selected backup contains too many photo files."
                )
            }
        }
    }

    static func validatedArchive(
        from url: URL,
        calendar: Calendar
    ) throws -> CookleDataArchive {
        guard url.startAccessingSecurityScopedResource() else {
            throw Failure.cannotAccessBackup
        }
        defer {
            url.stopAccessingSecurityScopedResource()
        }

        do {
            return try coordinatedValidatedArchive(
                from: url,
                calendar: calendar
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch let failure as Failure {
            throw failure
        } catch {
            throw Failure.invalidBackupContents
        }
    }
}

nonisolated private extension CookleBackupFileReader {
    static func coordinatedValidatedArchive(
        from url: URL,
        calendar: Calendar
    ) throws -> CookleDataArchive {
        let coordinator = NSFileCoordinator(
            filePresenter: nil
        )
        var coordinationError: NSError?
        var validationResult: Result<CookleDataArchive, Error>?
        coordinator.coordinate(
            readingItemAt: url,
            options: [],
            error: &coordinationError
        ) { coordinatedURL in
            validationResult = Result {
                try validatedArchiveContents(
                    from: coordinatedURL,
                    calendar: calendar
                )
            }
        }

        if let validationResult {
            return try validationResult.get()
        }
        if coordinationError != nil {
            throw Failure.cannotAccessBackup
        }
        throw Failure.cannotAccessBackup
    }

    static func validatedArchiveContents(
        from url: URL,
        calendar: Calendar
    ) throws -> CookleDataArchive {
        let resourceValues = try url.resourceValues(
            forKeys: [
                .isDirectoryKey,
                .isRegularFileKey,
                .isSymbolicLinkKey
            ]
        )
        guard resourceValues.isSymbolicLink != true else {
            throw Failure.invalidBackupFile
        }

        if resourceValues.isDirectory == true {
            return try DataMaintenanceOperations.validatedArchive(
                from: readBackupPackage(from: url),
                calendar: calendar
            )
        }

        guard resourceValues.isRegularFile == true else {
            throw Failure.invalidBackupFile
        }
        let data = try readBoundedData(
            from: url,
            maximumByteCount: DataMaintenanceOperations.maximumEncodedArchiveByteCount
        )
        return try DataMaintenanceOperations.validatedArchive(
            from: data,
            calendar: calendar
        )
    }

    static func readBackupPackage(
        from url: URL
    ) throws -> CookleDataArchivePackage {
        let rootEntries = try packageEntries(
            in: url,
            maximumEntryCount: Read.requiredPackageRootEntryCount,
            entryLimitError: .invalidBackupPackage
        )
        let expectedRootNames: Set<String> = [
            CookleDataArchivePackage.manifestFilename,
            CookleDataArchivePackage.photosDirectoryName
        ]
        guard Set(rootEntries.keys) == expectedRootNames,
              let manifestURL = rootEntries[
                CookleDataArchivePackage.manifestFilename
              ],
              let photosURL = rootEntries[
                CookleDataArchivePackage.photosDirectoryName
              ] else {
            throw Failure.invalidBackupPackage
        }

        try requireRegularFile(manifestURL)
        try requireDirectory(photosURL)

        let manifestData = try readBoundedData(
            from: manifestURL,
            maximumByteCount: DataMaintenanceOperations.maximumArchiveManifestByteCount
        )
        let photoEntries = try packageEntries(
            in: photosURL,
            maximumEntryCount: DataMaintenanceOperations.maximumArchivePhotoFileCount,
            entryLimitError: .tooManyPhotoFiles
        )
        let photoRead = try readPhotoFiles(
            from: photoEntries
        )
        _ = try addingByteCount(
            photoRead.totalByteCount,
            to: manifestData.count,
            maximumByteCount: DataMaintenanceOperations.maximumArchivePackageByteCount
        )
        return .init(
            manifestData: manifestData,
            photoFiles: photoRead.files
        )
    }

    static func readPhotoFiles(
        from entries: [String: URL]
    ) throws -> (files: [CookleDataArchivePackage.PhotoFile], totalByteCount: Int) {
        var totalByteCount = 0
        var photoFiles = [CookleDataArchivePackage.PhotoFile]()
        photoFiles.reserveCapacity(entries.count)

        for (filename, photoURL) in entries.sorted(by: { $0.key < $1.key }) {
            try Task.checkCancellation()
            try requireRegularFile(photoURL)
            let data = try readBoundedData(
                from: photoURL,
                maximumByteCount: DataMaintenanceOperations.maximumArchivePhotoByteCount
            )
            totalByteCount = try addingByteCount(
                data.count,
                to: totalByteCount,
                maximumByteCount: DataMaintenanceOperations.maximumArchiveAggregatePhotoByteCount
            )
            photoFiles.append(
                .init(
                    filename: filename,
                    data: data
                )
            )
        }
        return (
            files: photoFiles,
            totalByteCount: totalByteCount
        )
    }

    static func packageEntries(
        in directoryURL: URL,
        maximumEntryCount: Int,
        entryLimitError: Failure
    ) throws -> [String: URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [
                .isDirectoryKey,
                .isRegularFileKey,
                .isSymbolicLinkKey
            ],
            options: [
                .skipsPackageDescendants,
                .skipsSubdirectoryDescendants
            ]
        ) else {
            throw Failure.invalidBackupPackage
        }

        var entries = [String: URL]()
        while let entryURL = enumerator.nextObject() as? URL {
            try Task.checkCancellation()
            guard entries.count < maximumEntryCount else {
                throw entryLimitError
            }
            guard entries.updateValue(
                entryURL,
                forKey: entryURL.lastPathComponent
            ) == nil else {
                throw Failure.invalidBackupPackage
            }
        }
        return entries
    }

    static func requireRegularFile(_ url: URL) throws {
        let values = try url.resourceValues(
            forKeys: [
                .isRegularFileKey,
                .isSymbolicLinkKey
            ]
        )
        guard values.isRegularFile == true,
              values.isSymbolicLink != true else {
            throw Failure.invalidBackupPackage
        }
    }

    static func requireDirectory(_ url: URL) throws {
        let values = try url.resourceValues(
            forKeys: [
                .isDirectoryKey,
                .isSymbolicLinkKey
            ]
        )
        guard values.isDirectory == true,
              values.isSymbolicLink != true else {
            throw Failure.invalidBackupPackage
        }
    }

    static func readBoundedData(
        from url: URL,
        maximumByteCount: Int
    ) throws -> Data {
        let data = try readData(
            from: url,
            maximumByteCount: maximumByteCount
        )
        guard data.count <= maximumByteCount else {
            throw Failure.backupFileTooLarge
        }
        return data
    }

    static func addingByteCount(
        _ byteCount: Int,
        to totalByteCount: Int,
        maximumByteCount: Int
    ) throws -> Int {
        let (newTotalByteCount, didOverflow) = totalByteCount.addingReportingOverflow(
            byteCount
        )
        guard didOverflow == false,
              newTotalByteCount <= maximumByteCount else {
            throw Failure.backupFileTooLarge
        }
        return newTotalByteCount
    }

    static func readData(
        from url: URL,
        maximumByteCount: Int
    ) throws -> Data {
        let fileHandle = try FileHandle(
            forReadingFrom: url
        )
        defer {
            try? fileHandle.close()
        }

        var data = Data()
        while data.count <= maximumByteCount {
            try Task.checkCancellation()
            let remainingByteCount = maximumByteCount - data.count
            let readByteCount = min(
                remainingByteCount + 1,
                Read.chunkByteCount
            )
            let dataChunk = try fileHandle.read(
                upToCount: readByteCount
            )
            guard let dataChunk,
                  dataChunk.isEmpty == false else {
                break
            }
            data.append(dataChunk)
        }
        return data
    }
}
