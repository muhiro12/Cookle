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
