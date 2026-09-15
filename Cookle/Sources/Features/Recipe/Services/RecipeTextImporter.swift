import Foundation
import UIKit

enum RecipeTextImporter {
    static func recognize(in data: Data) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            guard let image = UIImage(data: data) else {
                throw RecipeTextImportError.imageDecodingFailed
            }

            let recognizedText: String
            do {
                recognizedText = try TextRecognitionService.recognize(in: image)
            } catch {
                throw RecipeTextImportError.textRecognitionFailed
            }

            let trimmedText = recognizedText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            guard trimmedText.isEmpty == false else {
                throw RecipeTextImportError.noRecognizedText
            }
            return trimmedText
        }.value
    }
}
