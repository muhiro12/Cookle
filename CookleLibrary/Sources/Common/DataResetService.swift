import SwiftData

/// Domain service to delete all persisted app data.
@MainActor
public enum DataResetService {
    public static func deleteAll(context: ModelContext) throws {
        try context.delete(model: Diary.self)
        try context.delete(model: DiaryObject.self)
        try context.delete(model: Recipe.self)
        try context.delete(model: Ingredient.self)
        try context.delete(model: IngredientObject.self)
        try context.delete(model: Category.self)
        try context.delete(model: Photo.self)
        try context.delete(model: PhotoObject.self)
    }
}
