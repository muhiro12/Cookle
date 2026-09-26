import Foundation
import SwiftData

/// What deleting a tag affects, captured as values when the deletion is reviewed.
///
/// Confirming re-resolves the tag and compares the recipes that use it by
/// identity and displayed names. An ingredient stays undeletable while any recipe uses it; a
/// category is removed from the recipes that use it while they stay saved.
public struct TagDeletionReview<T: Tag>: Equatable, Sendable {
    /// Identifier of the reviewed tag.
    public let tagID: PersistentIdentifier
    /// Tag value when the review was built.
    public let value: String
    /// Number of recipes that use the tag.
    public let recipeCount: Int
    /// A bounded set of those recipes' names in display order.
    public let recipeNameExamples: [String]

    private let recipeNames: [PersistentIdentifier: String]

    init(tag: T) {
        let recipes = MutationReviewExamples.uniqueModels(
            tag.recipes ?? []
        )
        tagID = tag.persistentModelID
        value = tag.value
        recipeCount = recipes.count
        recipeNameExamples = MutationReviewExamples.names(
            recipes.map(\.name)
        )
        recipeNames = Dictionary(uniqueKeysWithValues: recipes.map { recipe in
            (recipe.persistentModelID, recipe.name)
        })
    }

    /// Indicates whether `other` deletes the same tag and affects the same recipes.
    public func hasSameImpact(
        as other: Self
    ) -> Bool {
        tagID == other.tagID
            && value == other.value
            && recipeNames == other.recipeNames
    }
}
