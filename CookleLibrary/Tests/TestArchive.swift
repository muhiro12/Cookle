// swiftlint:disable no_magic_numbers
import Foundation

enum TestArchive {
    static let photoData = Data([1, 2, 3])
    static let photoOrder = 2
    static let ingredientOrder = 1
    static let servingSize = 2
    static let cookingTime = 15
    static let diaryTimestamp = TimeInterval(1_800)
    static let brokenPhotoOrder = 1
    static let brokenServingSize = 1
    static let brokenCookingTime = 1

    static var diaryDate: Date {
        Date(timeIntervalSince1970: diaryTimestamp)
    }
}
// swiftlint:enable no_magic_numbers
