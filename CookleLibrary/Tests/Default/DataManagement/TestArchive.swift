import Foundation

enum TestArchive {
    static let photoData = Data("test-photo-data".utf8)
    static let photoOrder = 2
    static let ingredientOrder = 1
    static let servingSize = 2
    static let cookingTime = 15
    static let diaryTimestamp: TimeInterval = 1_800
    static let brokenPhotoOrder = 1
    static let brokenServingSize = 1
    static let brokenCookingTime = 1
    static let unsupportedFormatVersion = 9_999
    static let duplicateIngredientIdentifier = "ingredient-1"
    static let missingRecipeIdentifier = "recipe-missing"

    static var diaryDate: Date {
        Date(timeIntervalSince1970: diaryTimestamp)
    }
}
