import Foundation
import SwiftData

/// What deleting a recipe removes, captured as values when the deletion is reviewed.
///
/// Confirming re-resolves the recipe and compares the affected diary meal rows
/// by identity, date, and meal type, along with the recipe name. Changes to
/// these reviewed values require confirmation again, even if counts stay equal.
public struct RecipeDeletionReview: Equatable, Sendable {
    /// A diary meal row the deletion removes.
    public struct MealRow: Equatable, Sendable {
        /// Day of the diary entry holding the row, when the row still has one.
        public let date: Date?
        /// Meal the row belongs to, when recorded.
        public let type: DiaryObjectType?
    }

    private struct MealImpact: Equatable, Sendable {
        let diaryID: PersistentIdentifier?
        let date: Date?
        let type: DiaryObjectType?
    }

    /// Identifier of the reviewed recipe.
    public let recipeID: PersistentIdentifier
    /// Recipe name when the review was built.
    public let recipeName: String
    /// Number of diary meal rows the deletion removes; the diary entries stay.
    public let mealRowCount: Int
    /// A bounded set of removed meal rows, most recent first.
    public let mealRowExamples: [MealRow]

    private let mealImpacts: [PersistentIdentifier: MealImpact]

    init(recipe: Recipe) {
        let mealRows = MutationReviewExamples.uniqueModels(
            recipe.diaryObjects ?? []
        )
        recipeID = recipe.persistentModelID
        recipeName = recipe.name
        mealRowCount = mealRows.count
        mealRowExamples = mealRows
            .sorted(by: Self.isMoreRecent)
            .prefix(MutationReviewExamples.limit)
            .map { mealRow in
                .init(
                    date: mealRow.diary?.date,
                    type: mealRow.type
                )
            }
        mealImpacts = Dictionary(uniqueKeysWithValues: mealRows.map { row in
            (row.persistentModelID, MealImpact(
                diaryID: row.diary?.persistentModelID,
                date: row.diary?.date,
                type: row.type
            ))
        })
    }

    /// Indicates whether `other` deletes the same recipe and removes the same meal rows.
    public func hasSameImpact(
        as other: Self
    ) -> Bool {
        recipeID == other.recipeID
            && recipeName == other.recipeName
            && mealImpacts == other.mealImpacts
    }
}

private extension RecipeDeletionReview {
    static func isMoreRecent(
        _ lhs: DiaryObject,
        _ rhs: DiaryObject
    ) -> Bool {
        switch (lhs.diary?.date, rhs.diary?.date) {
        case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
            return lhsDate > rhsDate
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        default:
            return mealIndex(of: lhs) < mealIndex(of: rhs)
        }
    }

    static func mealIndex(
        of mealRow: DiaryObject
    ) -> Int {
        guard let type = mealRow.type else {
            return DiaryObjectType.allCases.count
        }

        return DiaryObjectType.allCases.firstIndex(of: type) ?? DiaryObjectType.allCases.count
    }
}
