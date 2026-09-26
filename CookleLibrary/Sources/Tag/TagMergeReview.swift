import Foundation
import SwiftData

/// What merging duplicate-looking tags into one tag affects, captured as values
/// when the merge is reviewed.
///
/// Confirming re-resolves the kept tag, finds its duplicates again, and
/// compares both the duplicates and the recipes they move by identity and displayed names.
public struct TagMergeReview<T: Tag>: Equatable, Sendable {
    /// Identifier of the tag that is kept.
    public let keptTagID: PersistentIdentifier
    /// Kept tag value when the review was built.
    public let keptValue: String
    /// Number of duplicate tags the merge deletes.
    public let duplicateCount: Int
    /// A bounded set of the duplicate values in display order.
    public let duplicateValueExamples: [String]
    /// Number of recipes moved from a duplicate to the kept tag.
    public let recipeCount: Int
    /// A bounded set of those recipes' names in display order.
    public let recipeNameExamples: [String]

    private let duplicateValues: [PersistentIdentifier: String]
    private let recipeNames: [PersistentIdentifier: String]

    /// Indicates whether any duplicate remains to merge.
    public var hasDuplicates: Bool {
        duplicateCount > .zero
    }

    init(
        keeping tag: T,
        duplicates: [T],
        affectedRecipes: [Recipe]
    ) {
        let uniqueDuplicates = MutationReviewExamples.uniqueModels(
            duplicates
        )
        let uniqueRecipes = MutationReviewExamples.uniqueModels(
            affectedRecipes
        )
        keptTagID = tag.persistentModelID
        keptValue = tag.value
        duplicateCount = uniqueDuplicates.count
        duplicateValueExamples = MutationReviewExamples.names(
            uniqueDuplicates.map(\.value)
        )
        recipeCount = uniqueRecipes.count
        recipeNameExamples = MutationReviewExamples.names(
            uniqueRecipes.map(\.name)
        )
        duplicateValues = Dictionary(uniqueKeysWithValues: uniqueDuplicates.map { tag in
            (tag.persistentModelID, tag.value)
        })
        recipeNames = Dictionary(uniqueKeysWithValues: uniqueRecipes.map { recipe in
            (recipe.persistentModelID, recipe.name)
        })
    }

    /// Indicates whether `other` keeps the same tag and merges the same
    /// duplicates into the same recipes.
    public func hasSameImpact(
        as other: Self
    ) -> Bool {
        keptTagID == other.keptTagID
            && keptValue == other.keptValue
            && duplicateValues == other.duplicateValues
            && recipeNames == other.recipeNames
    }
}
