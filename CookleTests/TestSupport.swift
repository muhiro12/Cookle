import CookleLibrary
import Foundation
import SwiftData

@MainActor
func makeCookleTestContext() throws -> ModelContext {
    .init(
        try makeCookleTestContainer()
    )
}

@MainActor
func makeCookleTestContainer() throws -> ModelContainer {
    let schema = Schema(
        [
            Recipe.self,
            Diary.self,
            DiaryObject.self,
            Category.self,
            Ingredient.self,
            IngredientObject.self,
            Photo.self,
            PhotoObject.self
        ]
    )
    let configuration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true
    )
    return try ModelContainer(
        for: schema,
        configurations: [configuration]
    )
}

func makeTestUserDefaults() -> UserDefaults {
    let suiteName = "CookleTests.\(UUID().uuidString)"
    let userDefaults = UserDefaults(
        suiteName: suiteName
    ) ?? .standard
    userDefaults.removePersistentDomain(
        forName: suiteName
    )
    return userDefaults
}
