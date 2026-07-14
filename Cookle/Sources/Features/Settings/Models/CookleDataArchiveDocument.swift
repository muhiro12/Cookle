import Foundation
import SwiftUI
import UniformTypeIdentifiers

nonisolated struct CookleDataArchiveDocument: FileDocument {
    static let readableContentTypes = [UTType]()

    static let writableContentTypes: [UTType] = [
        .cookleBackup
    ]

    static var importableContentTypes: [UTType] {
        [
            .cookleBackup,
            .json
        ]
    }

    let archivePackage: CookleDataArchivePackage

    init(archivePackage: CookleDataArchivePackage) {
        self.archivePackage = archivePackage
    }

    init(configuration _: ReadConfiguration) throws {
        throw CocoaError(.featureUnsupported)
    }

    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        var photoWrappers = [String: FileWrapper]()
        for photoFile in archivePackage.photoFiles {
            guard photoWrappers.updateValue(
                .init(regularFileWithContents: photoFile.data),
                forKey: photoFile.filename
            ) == nil else {
                throw CocoaError(.fileWriteFileExists)
            }
        }

        return .init(
            directoryWithFileWrappers: [
                CookleDataArchivePackage.manifestFilename: .init(
                    regularFileWithContents: archivePackage.manifestData
                ),
                CookleDataArchivePackage.photosDirectoryName: .init(
                    directoryWithFileWrappers: photoWrappers
                )
            ]
        )
    }
}
