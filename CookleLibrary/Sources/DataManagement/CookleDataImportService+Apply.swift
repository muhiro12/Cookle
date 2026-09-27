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

        do {
            let summary = try CookleDataImportApplier(
                archive: archive,
                review: review,
                selections: selections,
                context: context
            )
            .apply()
            try save(context)
            return summary
        } catch {
            context.rollback()
            throw error
        }
    }
}
