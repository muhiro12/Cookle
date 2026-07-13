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
        try deleteAll(Diary.self, context: context)
        try deleteAll(DiaryObject.self, context: context)
        try deleteAll(Recipe.self, context: context)
        try deleteAll(Ingredient.self, context: context)
        try deleteAll(IngredientObject.self, context: context)
        try deleteAll(Category.self, context: context)
        try deleteAll(Photo.self, context: context)
        try deleteAll(PhotoObject.self, context: context)
        return .init(
            value: (),
            effects: [
                .diaryDataChanged,
                .recipeDataChanged,
                .notificationPlanChanged
            ]
        )
    }

    private static func deleteAll<Model: PersistentModel>(
        _: Model.Type,
        context: ModelContext
    ) throws {
        for model in try context.fetch(
            FetchDescriptor<Model>()
        ) {
            context.delete(model)
        }
    }
}
