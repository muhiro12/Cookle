/// Why a merge import review could not be built or applied.
///
/// Every case leaves current data unchanged.
public enum CookleDataImportError: Error, Equatable, Sendable {
    /// A day the backup touches already has more than one current diary.
    case duplicateCurrentDiaryDays
    /// Current data or the backup no longer matches the review; the value is
    /// the review rebuilt from the current state.
    case reviewChanged(CookleDataImportReview)
    /// A conflict has no choice, a choice names no conflict, or a choice
    /// targets a recipe that is not one of its candidates or is targeted twice.
    case invalidSelections
}
