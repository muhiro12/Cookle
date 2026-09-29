import SwiftData

/// The choices made for every conflict in an import review.
public struct CookleDataImportSelections: Equatable, Sendable {
    /// Choices keyed by recipe conflict identifier.
    public var recipeChoices: [String: CookleDataRecipeImportChoice]
    /// Choices keyed by diary conflict identifier.
    public var diaryChoices: [String: CookleDataDiaryImportChoice]

    /// Creates selections with no choices made.
    public init(
        recipeChoices: [String: CookleDataRecipeImportChoice] = [:],
        diaryChoices: [String: CookleDataDiaryImportChoice] = [:]
    ) {
        self.recipeChoices = recipeChoices
        self.diaryChoices = diaryChoices
    }

    /// Choices that update matching current data with the file's content.
    ///
    /// Each recipe conflict updates its oldest candidate that no other imported
    /// recipe keeps or updates, and adds the imported recipe separately when no
    /// candidate is left. Each diary conflict replaces that day's meals and note.
    /// The result always resolves every conflict in `review` validly.
    public static func updatingMatchingData(
        for review: CookleDataImportReview
    ) -> Self {
        var keptTargets = Set(review.unchangedRecipeTargets.values)
        var replacedTargets = Set<PersistentIdentifier>()
        var selections = Self()
        for conflict in review.recipeConflicts {
            if let identical = conflict.candidates.first(where: { candidate in
                candidate.isIdenticalToBackup
                    && replacedTargets.contains(candidate.id) == false
            }) {
                selections.recipeChoices[conflict.id] = .keepCurrent(identical.id)
                keptTargets.insert(identical.id)
            } else if let candidate = conflict.candidates.first(where: { candidate in
                keptTargets.contains(candidate.id) == false
                    && replacedTargets.contains(candidate.id) == false
            }) {
                selections.recipeChoices[conflict.id] = .useBackup(candidate.id)
                replacedTargets.insert(candidate.id)
            } else {
                selections.recipeChoices[conflict.id] = .keepBoth
            }
        }
        for conflict in review.diaryConflicts {
            selections.diaryChoices[conflict.id] = .useBackup
        }
        return selections
    }

    /// Indicates whether every conflict in `review` has a valid choice.
    public func isComplete(
        for review: CookleDataImportReview
    ) -> Bool {
        (try? CookleDataImportService.validate(self, for: review)) != nil
    }

    /// Keeps only the choices whose conflicts are unchanged between the
    /// review they were made for and `currentReview`, so a changed conflict
    /// must be chosen again.
    public func retainingUnchangedChoices(
        from previousReview: CookleDataImportReview,
        in currentReview: CookleDataImportReview
    ) -> Self {
        let previousRecipeConflicts = Dictionary(
            uniqueKeysWithValues: previousReview.recipeConflicts.map { conflict in
                (conflict.id, conflict)
            }
        )
        let previousDiaryConflicts = Dictionary(
            uniqueKeysWithValues: previousReview.diaryConflicts.map { conflict in
                (conflict.id, conflict)
            }
        )
        var retained = Self()
        for conflict in currentReview.recipeConflicts
        where previousRecipeConflicts[conflict.id] == conflict {
            retained.recipeChoices[conflict.id] = recipeChoices[conflict.id]
        }
        for conflict in currentReview.diaryConflicts
        where previousDiaryConflicts[conflict.id] == conflict {
            retained.diaryChoices[conflict.id] = diaryChoices[conflict.id]
        }
        return retained
    }
}
