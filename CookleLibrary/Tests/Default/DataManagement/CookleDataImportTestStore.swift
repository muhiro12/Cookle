@testable import CookleLibrary
import Foundation
import SwiftData

/// Builds small stores for merge-import tests through the same creation paths the app uses.
@MainActor
struct CookleDataImportTestStore {
    enum TestValues {
        static let servingSize = 2
        static let cookingTimeMinutes = 20
        static let year = 2_026
        static let month = 9
        static let hour = 12
    }

    struct Meal {
        let recipe: Recipe
        let type: DiaryObjectType
    }

    static var calendar: Calendar {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = .gmt
        return gregorian
    }

    let context: ModelContext

    init(context: ModelContext = makeTestContext()) {
        self.context = context
    }

    static func date(day: Int) -> Date {
        calendar.date(
            from: .init(
                year: TestValues.year,
                month: TestValues.month,
                day: day,
                hour: TestValues.hour
            )
        ) ?? .distantPast
    }

    static func photo(_ text: String, source: PhotoSource = .photosPicker) -> PhotoData {
        .init(data: Data(text.utf8), source: source)
    }

    @discardableResult
    func recipe(
        _ name: String,
        ingredients: [(String, String)] = [],
        steps: [String] = [],
        categories: [String] = [],
        photos: [PhotoData] = [],
        note: String = ""
    ) throws -> Recipe {
        Recipe.create(
            context: context,
            content: .init(
                name: name,
                photos: try photos.enumerated().map { index, photo in
                    try PhotoObject.create(context: context, photoData: photo, order: index + 1)
                },
                servingSize: TestValues.servingSize,
                cookingTime: TestValues.cookingTimeMinutes,
                ingredients: try ingredients.enumerated().map { index, ingredient in
                    try IngredientObject.create(
                        context: context,
                        ingredient: ingredient.0,
                        amount: ingredient.1,
                        order: index + 1
                    )
                },
                steps: steps,
                categories: try categories.map { category in
                    try CookleLibrary.Category.create(context: context, value: category)
                },
                note: note
            )
        )
    }

    @discardableResult
    func diary(day: Int, meals: [Meal], note: String = "") -> Diary {
        Diary.create(
            context: context,
            content: .init(
                date: Self.date(day: day),
                objects: meals.enumerated().map { index, meal in
                    DiaryObject.create(context: context, recipe: meal.recipe, type: meal.type, order: index + 1)
                },
                note: note
            )
        )
    }

    func archive() throws -> CookleDataArchive {
        try context.save()
        return try CookleDataArchiveService.makeArchive(context: context)
    }

    func review(of archive: CookleDataArchive) throws -> CookleDataImportReview {
        try DataMaintenanceOperations.importReview(
            for: archive,
            context: context,
            calendar: Self.calendar
        )
    }

    func recipes(named name: String) throws -> [Recipe] {
        try context.fetch(.recipes(.all)).filter { recipe in
            recipe.name == name
        }
    }

    func count<Model: PersistentModel>(_: Model.Type) throws -> Int {
        try context.fetchCount(FetchDescriptor<Model>())
    }
}
