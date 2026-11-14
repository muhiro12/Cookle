import SwiftData

/// Counts only; no record contents, identifiers, or storage paths leave the read boundary.
public struct DiagnosticRecordCounts: Equatable, Sendable {
    public let diaries: Int
    public let diaryObjects: Int
    public let recipes: Int
    public let photos: Int
    public let photoObjects: Int
    public let ingredients: Int
    public let ingredientObjects: Int
    public let categories: Int

    /// Includes detached structural rows when deciding whether a store is empty.
    public var isEmpty: Bool {
        [diaries, diaryObjects, recipes, photos, photoObjects, ingredients, ingredientObjects, categories]
            .allSatisfy { count in
                count == .zero
            }
    }

    /// Reads persisted counts without saving or discarding the caller's pending changes.
    @preconcurrency
    @MainActor
    public static func read(container: ModelContainer) throws -> Self {
        let context = ModelContext(container)
        return try .init(
            diaries: context.fetchCount(FetchDescriptor<Diary>()),
            diaryObjects: context.fetchCount(FetchDescriptor<DiaryObject>()),
            recipes: context.fetchCount(FetchDescriptor<Recipe>()),
            photos: context.fetchCount(FetchDescriptor<Photo>()),
            photoObjects: context.fetchCount(FetchDescriptor<PhotoObject>()),
            ingredients: context.fetchCount(FetchDescriptor<Ingredient>()),
            ingredientObjects: context.fetchCount(FetchDescriptor<IngredientObject>()),
            categories: context.fetchCount(FetchDescriptor<Category>())
        )
    }
}
