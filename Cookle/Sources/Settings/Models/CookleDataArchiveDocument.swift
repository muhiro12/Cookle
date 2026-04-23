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
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        self.data = data
    }

    func fileWrapper(configuration _: WriteConfiguration) -> FileWrapper {
        .init(
            regularFileWithContents: data
        )
    }
}
