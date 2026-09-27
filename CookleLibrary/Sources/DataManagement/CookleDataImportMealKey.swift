import SwiftData

/// A diary meal row compared by meal and resolved recipe.
struct CookleDataImportMealKey: Hashable {
    let type: DiaryObjectType
    let recipeID: PersistentIdentifier

    /// Counts how many rows share each meal and recipe.
    static func counts(_ keys: [Self]) -> [Self: Int] {
        keys.reduce(into: [:]) { counts, key in
            counts[key, default: .zero] += 1
        }
    }

    /// Position of a meal in the day, placing unknown meals last.
    static func index(of type: DiaryObjectType?) -> Int {
        guard let type else {
            return DiaryObjectType.allCases.count
        }

        return DiaryObjectType.allCases.firstIndex(of: type) ?? DiaryObjectType.allCases.count
    }
}

extension CookleDataImportService {
    typealias MealKey = CookleDataImportMealKey
}
