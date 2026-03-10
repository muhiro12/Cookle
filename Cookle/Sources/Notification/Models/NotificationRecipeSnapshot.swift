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
            ingredientNames: recipe.ingredientObjects.orEmpty.sorted().compactMap { object in
                object.ingredient?.value
            },
            steps: recipe.steps,
            note: recipe.note,
            cookingTime: recipe.cookingTime,
            servingSize: recipe.servingSize,
            modifiedTimestamp: recipe.modifiedTimestamp
        )
    }

    private static func primaryPhotoData(
        recipe: Recipe
    ) -> Data? {
        if let photoData = recipe.photoObjects?.min()?.photo?.data {
            return photoData
        }
        return recipe.photos?.first?.data
    }
}
