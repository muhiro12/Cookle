import Foundation

enum RecipeTextImportError: LocalizedError, Sendable {
    case photoDataUnavailable
    case imageDecodingFailed
    case textRecognitionFailed
    case noRecognizedText

    var errorDescription: String? {
        switch self {
        case .photoDataUnavailable:
            String(
                localized: "The selected photo could not be loaded. Choose another photo and try again.",
                comment: "Error shown when the recipe text importer cannot load a photo library selection."
            )
        case .imageDecodingFailed:
            String(
                localized: "The photo could not be read. Choose another photo and try again.",
                comment: "Error shown when the recipe text importer cannot decode the selected or captured image."
            )
        case .textRecognitionFailed:
            String(
                localized: "Text recognition failed. Try again with a clearer photo.",
                comment: "Error shown when Vision fails to recognize recipe text in a photo."
            )
        case .noRecognizedText:
            String(
                localized: "No text was found in the photo. Try again with a photo that contains clear text.",
                comment: "Error shown when text recognition succeeds but finds no recipe text in a photo."
            )
        }
    }
}
