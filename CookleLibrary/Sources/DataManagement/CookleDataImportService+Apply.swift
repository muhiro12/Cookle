import Foundation
import SwiftData

extension CookleDataImportService {
    /// Merges the archive into current data using the reviewed choices.
    ///
    /// The review is rebuilt first; if current data or the archive no longer
    /// matches the approved review, nothing changes and the rebuilt review is
    /// thrown for a new confirmation. Every change is saved together, and any
    /// failure rolls the context back to the state before the import.
    static func apply(
        _ archive: CookleDataArchive,
        review: CookleDataImportReview,
        selections: CookleDataImportSelections,
        context: ModelContext,
        save: (ModelContext) throws -> Void = { context in
            try context.save()
        }
    ) throws -> CookleDataImportSummary {
        guard context.hasChanges == false else {
            throw CookleDataImportError.pendingChanges
        }
        try Task.checkCancellation()
        try CookleDataArchiveService.validate(
            archive,
            calendar: review.calendar,
            limits: .standard
        )
        let currentReview = try self.review(
            for: archive,
            context: context,
            calendar: review.calendar
        )
        guard currentReview == review else {
            throw CookleDataImportError.reviewChanged(currentReview)
        }
        try validate(
            selections,
            for: review
        )

        return try applyWithRecovery(
            CookleDataImportApplier(
                archive: archive,
                review: review,
                selections: selections,
                context: context
            ),
            context: context,
            save: save
        )
    }

    private static func applyWithRecovery(
        _ applier: CookleDataImportApplier,
        context: ModelContext,
        save: (ModelContext) throws -> Void
    ) throws -> CookleDataImportSummary {
        // On iOS 18.6, rollback alone leaves loaded scalar values stale. Native
        // undo restores the visible graph before rollback clears pending changes.
        let previousUndoManager = context.undoManager
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        context.undoManager = undoManager
        undoManager.beginUndoGrouping()
        defer {
            context.undoManager = previousUndoManager
        }
        do {
            let summary = try applier.apply()
            context.processPendingChanges()
            if undoManager.groupingLevel > 0 {
                undoManager.endUndoGrouping()
            }
            try save(context)
            return summary
        } catch {
            context.processPendingChanges()
            if undoManager.groupingLevel > 0 {
                undoManager.endUndoGrouping()
            }
            undoManager.undo()
            context.rollback()
            throw error
        }
    }
}
