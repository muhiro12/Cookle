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

    nonisolated func hasMatchingRecipeAndDiaryCounts(as legacyObjectCounts: Self) -> Bool {
        recipeCount == legacyObjectCounts.recipeCount
            && diaryCount == legacyObjectCounts.diaryCount
    }
}
