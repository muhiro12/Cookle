/// Counts of what a merge import changed.
public struct CookleDataImportSummary: Equatable, Sendable {
    /// Imported recipes added as new recipes, including kept-both versions.
    public let addedRecipeCount: Int
    /// Current recipes replaced by their imported versions.
    public let updatedRecipeCount: Int
    /// Current recipes kept instead of their conflicting imported versions.
    public let keptRecipeCount: Int
    /// Imported recipes identical to current recipes.
    public let unchangedRecipeCount: Int
    /// Imported diaries added on days without a diary.
    public let addedDiaryCount: Int
    /// Diary days replaced by their imported versions.
    public let updatedDiaryCount: Int
    /// Diary days that now hold both versions.
    public let combinedDiaryCount: Int
    /// Diary days kept instead of their conflicting imported versions.
    public let keptDiaryCount: Int
    /// Imported diaries identical to current diaries.
    public let unchangedDiaryCount: Int
    /// Photos added because no current photo had the same image and source.
    public let addedPhotoCount: Int
}
