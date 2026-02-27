@testable import CookleLibrary
import SwiftData

// Lightweight in-memory ModelContext for library tests
func makeTestContext() -> ModelContext {
    let schema = Schema([
        Recipe.self,
        Diary.self,
        DiaryObject.self,
        Category.self,
        Ingredient.self,
        IngredientObject.self,
        Photo.self,
        PhotoObject.self
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container: ModelContainer
    do {
        container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    } catch {
        fatalError("Failed to create in-memory ModelContainer: \(error)")
    }
    return .init(container)
}
