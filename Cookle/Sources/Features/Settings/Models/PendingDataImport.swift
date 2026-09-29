import Foundation

/// A validated export file waiting for the person to choose how to import it.
///
/// The archive stays with the review so a retry after a recoverable failure,
/// or after current data changed, rebuilds the review without reopening the file.
struct PendingDataImport {
    let archive: CookleDataArchive
    var review: CookleDataImportReview
    var presentationID = UUID()
    /// Choices made per conflict when importing item by item.
    var selections = CookleDataImportSelections()
    /// Indicates that current data changed and the review was rebuilt.
    var isReviewRefreshed = false

    /// Indicates whether the file holds a complete library that can replace current data.
    var canReplace: Bool {
        archive.scope == .all
    }

    /// Indicates whether current data holds anything the import could collide with.
    var needsMethodChoice: Bool {
        review.isCurrentDataEmpty == false
    }

    var hasIncompatibleChoices: Bool {
        selections.recipeChoices.count == review.recipeConflicts.count
            && selections.diaryChoices.count == review.diaryConflicts.count
            && isReadyToImport == false
    }

    /// Indicates whether every conflict has a valid per-item choice.
    var isReadyToImport: Bool {
        selections.isComplete(for: review)
    }
}
