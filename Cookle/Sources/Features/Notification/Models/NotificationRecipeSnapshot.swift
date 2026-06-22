import Foundation

nonisolated struct NotificationRecipeSnapshot: Sendable, Equatable {
    let name: String
    let stableIdentifier: String
    let primaryPhotoData: Data?
    let ingredientNames: [String]
    let steps: [String]
    let note: String
    let cookingTime: Int
    let servingSize: Int
    let madeCount: Int
    let lastCookedDate: Date?
    let modifiedTimestamp: Date

    var hasPhoto: Bool {
        primaryPhotoData != nil
    }

    var ingredientCount: Int {
        ingredientNames.count
    }
}

nonisolated extension NotificationRecipeSnapshot {
    static func make(
        recipe: Recipe
    ) -> Self {
        .init(
            name: recipe.name,
            stableIdentifier: RecipeStableIdentifierCodec.stableIdentifier(
                for: recipe
            ),
            primaryPhotoData: primaryPhotoData(
                recipe: recipe
            ),
            ingredientNames: (recipe.ingredientObjects ?? []).sorted().compactMap { object in
                object.ingredient?.value
            },
            steps: recipe.steps,
            note: recipe.note,
            cookingTime: recipe.cookingTime,
            servingSize: recipe.servingSize,
            madeCount: (recipe.diaryObjects ?? []).count,
            lastCookedDate: lastCookedDate(
                recipe: recipe
            ),
            modifiedTimestamp: recipe.modifiedTimestamp
        )
    }

    private static func primaryPhotoData(
        recipe: Recipe
    ) -> Data? {
        recipe.primaryPhotoData
    }

    private static func lastCookedDate(
        recipe: Recipe
    ) -> Date? {
        (recipe.diaryObjects ?? [])
            .compactMap { diaryObject in
                diaryObject.diary?.date
            }
            .max()
    }
}
