/// Counts restored from a validated Cookle data archive.
public struct CookleDataRestoreSummary: Sendable {
    public let ingredientCount: Int
    public let categoryCount: Int
    public let photoCount: Int
    public let recipeCount: Int
    public let diaryCount: Int
}
