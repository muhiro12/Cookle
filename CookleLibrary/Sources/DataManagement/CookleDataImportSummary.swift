/// Counts of what a merge import changed.
public struct CookleDataImportSummary: Equatable, Sendable {
    /// Backup recipes added as new recipes, including kept-both versions.
    public let addedRecipeCount: Int
    /// Current recipes replaced by their backup versions.
    public let updatedRecipeCount: Int
    /// Current recipes kept instead of their conflicting backup versions.
    public let keptRecipeCount: Int
    /// Backup recipes identical to current recipes.
    public let unchangedRecipeCount: Int
    /// Backup diaries added on days without a diary.
    public let addedDiaryCount: Int
    /// Diary days replaced by their backup versions.
    public let updatedDiaryCount: Int
    /// Diary days that now hold both versions.
    public let combinedDiaryCount: Int
    /// Diary days kept instead of their conflicting backup versions.
    public let keptDiaryCount: Int
    /// Backup diaries identical to current diaries.
    public let unchangedDiaryCount: Int
    /// Photos added because no current photo had the same image and source.
    public let addedPhotoCount: Int
}
