import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct CookleDataArchiveDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [
            .json
        ]
    }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let fileData = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        self.data = fileData
    }

    func fileWrapper(configuration _: WriteConfiguration) -> FileWrapper {
        .init(
            regularFileWithContents: data
        )
    }
}
