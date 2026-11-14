import CookleLibrary
import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// A value snapshot keeps deferred system transfers independent of the stored Photo.
struct PhotoShareItem: Transferable, Sendable {
    enum ExportError: Error {
        case unreadableImage
    }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            guard let pngData = PhotoImageProcessor.sharePNGData(from: item.data) else {
                throw ExportError.unreadableImage
            }
            return pngData
        }
        .suggestedFileName("Cookle-Photo.png")
    }

    let data: Data
}
