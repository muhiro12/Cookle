import Foundation
import SwiftData

/// What merging a validated export file into the current data would do, built
/// without changing the store.
///
/// Records that match nothing are added, records identical to current data are
/// left unchanged, and every other collision becomes a conflict that needs a
/// choice before the import can apply, either made per conflict or produced by
/// `CookleDataImportSelections.updatingMatchingData(for:)`. File identifiers
/// are file-local and are never compared with current records; matching uses
/// recipe names and diary calendar days, and equality uses content.
public struct CookleDataImportReview: Equatable, Sendable {
    /// One photo as shown when comparing recipe versions.
    public struct PhotoSnapshot: Equatable, Sendable {
        /// Image bytes for display.
        public let data: Data
        /// Stored photo source identifier.
        public let sourceID: String
        /// SHA-256 digest of the image bytes, stable for the same image.
        public let digest: Data

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.digest == rhs.digest && lhs.sourceID == rhs.sourceID
        }
    }

    /// One ingredient row as shown when comparing recipe versions.
    public struct IngredientSnapshot: Equatable, Sendable {
        /// Ingredient name.
        public let name: String
        /// Amount text.
        public let amount: String
    }

    /// Comparable content of one recipe version.
    public struct RecipeSnapshot: Equatable, Sendable {
        /// Recipe name.
        public let name: String
        /// Number of servings; zero when unknown.
        public let servingSize: Int
        /// Cooking time in minutes; zero when unknown.
        public let cookingTime: Int
        /// Ingredient rows in recipe order.
        public let ingredients: [IngredientSnapshot]
        /// Steps in recipe order.
        public let steps: [String]
        /// Category names in display order.
        public let categories: [String]
        /// Recipe note.
        public let note: String
        /// Photos in recipe order.
        public let photos: [PhotoSnapshot]
    }

    /// A current recipe the imported recipe could correspond to.
    public struct RecipeCandidate: Equatable, Sendable, Identifiable {
        /// Identifier of the current recipe.
        public let id: PersistentIdentifier
        /// Current content.
        public let recipe: RecipeSnapshot
        /// Diary meal rows that show this recipe, which also show imported
        /// content if the imported version replaces it.
        public let diaryMealRowCount: Int
        /// Indicates whether the imported content is identical to this recipe.
        public let isIdenticalToBackup: Bool
        let diaryReview: RecipeDeletionReview
    }

    /// An imported recipe whose name matches only current recipes with
    /// different content.
    public struct RecipeConflict: Equatable, Sendable, Identifiable {
        /// File-local identifier, valid only within this review.
        public let id: String
        /// Imported content.
        public let backup: RecipeSnapshot
        /// Current recipes with the same name, in display order.
        public let candidates: [RecipeCandidate]
    }

    /// One meal row as shown when comparing diary versions.
    public struct DiaryMealSnapshot: Equatable, Sendable {
        /// Meal the row belongs to.
        public let type: DiaryObjectType
        /// Name of the recipe the row shows.
        public let recipeName: String
        let recipeID: PersistentIdentifier?
    }

    /// Comparable content of one diary day.
    public struct DiarySnapshot: Equatable, Sendable {
        /// Meal rows grouped by meal and ordered within each meal.
        public let meals: [DiaryMealSnapshot]
        /// Diary note.
        public let note: String
    }

    /// An imported diary for a calendar day that already has a different diary.
    public struct DiaryConflict: Equatable, Sendable, Identifiable {
        /// File-local identifier, valid only within this review.
        public let id: String
        /// Start of the calendar day both diaries belong to.
        public let day: Date
        /// Current diary content.
        public let current: DiarySnapshot
        /// Imported diary content.
        public let backup: DiarySnapshot

        let currentDiaryID: PersistentIdentifier
    }

    /// Calendar used to match diary days; applying uses the same calendar.
    public let calendar: Calendar
    /// Indicates whether the store held no records at all, so merging adds
    /// everything and no import method needs choosing.
    public let isCurrentDataEmpty: Bool
    /// Imported recipes that match no current recipe and will be added.
    public let newRecipeCount: Int
    /// Imported recipes identical to a current recipe, left unchanged.
    public let unchangedRecipeCount: Int
    /// Imported diaries on days without a current diary, which will be added.
    public let newDiaryCount: Int
    /// Imported diaries identical to the current diary of their day, left unchanged.
    public let unchangedDiaryCount: Int
    /// Recipe collisions that each need a choice.
    public let recipeConflicts: [RecipeConflict]
    /// Diary day collisions that each need a choice.
    public let diaryConflicts: [DiaryConflict]

    let archiveIdentity: Data
    let unchangedRecipeTargets: [String: PersistentIdentifier]
    let unchangedDiaryTargets: [String: PersistentIdentifier]

    /// Indicates whether anything needs a choice before importing.
    public var hasConflicts: Bool {
        recipeConflicts.isEmpty == false || diaryConflicts.isEmpty == false
    }
}
