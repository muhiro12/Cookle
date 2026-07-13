import Foundation

/// Semantic recipe form state used to detect unsaved changes.
public struct RecipeFormChangeSnapshot: Equatable, Sendable {
    private struct Photo: Equatable, Sendable {
        let data: Data
        let sourceRawValue: String

        init(_ photoData: PhotoData) {
            data = photoData.data
            sourceRawValue = photoData.source.rawValue
        }
    }

    private enum Number: Equatable, Sendable {
        case value(Int)
        case invalid(String)
    }

    private let name: String
    private let photos: [Photo]
    private let servingSize: Number
    private let cookingTime: Number
    private let ingredients: [RecipeFormIngredientInput]
    private let steps: [String]
    private let categories: [String]
    private let note: String

    /// Creates a snapshot using the same placeholder and number semantics as recipe saving.
    public init(input: RecipeFormInput) {
        name = input.name
        photos = input.photos.map(Photo.init)
        servingSize = Self.number(from: input.servingSize)
        cookingTime = Self.number(from: input.cookingTime)
        ingredients = input.ingredients.filter { ingredient in
            ingredient.ingredient.isEmpty == false
        }
        steps = input.steps.filter { step in
            step.isEmpty == false
        }
        categories = input.categories.filter { category in
            category.isEmpty == false
        }
        note = input.note
    }
}

private extension RecipeFormChangeSnapshot {
    private static func number(from input: String) -> Number {
        guard input.isEmpty == false else {
            return .value(.zero)
        }

        let normalizedInput = input.applyingTransform(
            .fullwidthToHalfwidth,
            reverse: false
        ) ?? ""
        guard let value = Int(normalizedInput) else {
            return .invalid(input)
        }

        return .value(value)
    }
}
