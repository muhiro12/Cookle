//
//  OCRRecipeBuilder.swift
//  Cookle
//
//  Created by codex on 2025/06/30.
//

import SwiftUI
import Vision

struct RecipeDraft {
    var name = String.empty
    var servingSize = String.empty
    var cookingTime = String.empty
    var ingredients = [RecipeFormIngredient]()
    var steps = [String]()
    var note = String.empty
}

enum OCRRecipeBuilder {
    enum OCRRecipeBuilderError: Error {
        case invalidImage
        case unsupported
    }

    @available(iOS 19.0, *)
    static func build(from data: Data) async throws -> RecipeDraft {
        guard CookleFoundationModel.isSupported else {
            throw OCRRecipeBuilderError.unsupported
        }
        guard let image = UIImage(data: data)?.cgImage else {
            throw OCRRecipeBuilderError.invalidImage
        }
        let request = VNRecognizeTextRequest()
        let handler = VNImageRequestHandler(cgImage: image)
        try handler.perform([request])
        let text = request.results?
            .compactMap { ($0 as? VNRecognizedTextObservation)?.topCandidates(1).first?.string }
            .joined(separator: "\n") ?? .empty
        return try await CookleFoundationModel.summarizeRecipe(text)
    }
}
