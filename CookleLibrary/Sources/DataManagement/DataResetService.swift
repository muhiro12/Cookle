import SwiftData

/// Internal data-reset collaborator used by public Operations.
@preconcurrency
@MainActor
enum DataResetService {
    /// Deletes every persisted Cookle model from the supplied context.
    static func deleteAll(context: ModelContext) throws {
        _ = try deleteAllWithOutcome(
            context: context
        )
    }

    /// Deletes every persisted Cookle model and returns follow-up hints.
    static func deleteAllWithOutcome(
        context: ModelContext
    ) throws -> MutationOutcome<Void> {
        try context.delete(model: Diary.self)
        try context.delete(model: DiaryObject.self)
        try context.delete(model: Recipe.self)
        try context.delete(model: Ingredient.self)
        try context.delete(model: IngredientObject.self)
        try context.delete(model: Category.self)
        try context.delete(model: Photo.self)
        try context.delete(model: PhotoObject.self)
        return .init(
            value: (),
            effects: [
                .diaryDataChanged,
                .recipeDataChanged,
                .notificationPlanChanged
            ]
        )
    }
}
