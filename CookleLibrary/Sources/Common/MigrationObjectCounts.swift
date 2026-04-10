struct MigrationObjectCounts: Equatable {
    let recipeCount: Int
    let diaryCount: Int
    let categoryCount: Int
    let ingredientCount: Int
    let photoCount: Int

    nonisolated var summary: String {
        [
            "recipe=\(recipeCount)",
            "diary=\(diaryCount)",
            "category=\(categoryCount)",
            "ingredient=\(ingredientCount)",
            "photo=\(photoCount)"
        ].joined(separator: ", ")
    }

    nonisolated func hasMatchingPersistedEntityCounts(
        as legacyObjectCounts: Self
    ) -> Bool {
        self == legacyObjectCounts
    }
}
