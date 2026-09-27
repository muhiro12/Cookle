import Foundation

/// A validated backup waiting for its merge review to be confirmed.
///
/// The archive stays with the review so a retry after a recoverable failure,
/// or after current data changed, rebuilds the review without reopening the file.
struct PendingBackupImport {
    let archive: CookleDataArchive
    var review: CookleDataImportReview
    var presentationID = UUID()
    var selections = CookleDataImportSelections()
    /// Indicates that current data changed and the review was rebuilt.
    var isReviewRefreshed = false

    var hasIncompatibleChoices: Bool {
        selections.recipeChoices.count == review.recipeConflicts.count
            && selections.diaryChoices.count == review.diaryConflicts.count
            && isReadyToImport == false
    }

    var isReadyToImport: Bool {
        selections.isComplete(for: review)
    }
}
