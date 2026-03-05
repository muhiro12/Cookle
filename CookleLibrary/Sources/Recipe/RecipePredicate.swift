//
//  RecipePredicate.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

/// Predicates describing how to filter `Recipe` records.
nonisolated public enum RecipePredicate {
    /// Matches every recipe.
    case all
    /// Matches no recipes.
    case none // swiftlint:disable:this discouraged_none_name
    /// Matches the recipe with the supplied persistent identifier.
    case idIs(Recipe.ID)
    /// Matches recipes whose name contains the supplied text.
    case nameContains(String)
    /// Name OR ingredient OR category matches. For short text (<3), tags use equality; otherwise contains.
    case anyTextMatches(String)

    private static let shortTextThreshold = Int("3") ?? .zero

    /// Concrete SwiftData predicate for this case.
    public var value: Predicate<Recipe> {
        switch self {
        case .all:
            return .true
        case .none:
            return .false
        case .idIs(let id):
            return #Predicate<Recipe> { recipe in
                recipe.persistentModelID == id
            }
        case .nameContains(let name):
            let hiragana = name.applyingTransform(.hiraganaToKatakana, reverse: true).orEmpty
            let katakana = name.applyingTransform(.hiraganaToKatakana, reverse: false).orEmpty
            return #Predicate<Recipe> { recipe in
                recipe.name.localizedStandardContains(name)
                    || recipe.name.localizedStandardContains(hiragana)
                    || recipe.name.localizedStandardContains(katakana)
            }
        case .anyTextMatches(let text):
            if text.count < Self.shortTextThreshold {
                return #Predicate<Recipe> { recipe in
                    recipe.name.localizedStandardContains(text)
                        || (recipe.ingredients?.contains { ingredient in ingredient.value == text }) == true
                        || (recipe.categories?.contains { category in category.value == text }) == true
                }
            }
            return #Predicate<Recipe> { recipe in
                recipe.name.localizedStandardContains(text)
                    || (recipe.ingredients?.contains { ingredient in
                        ingredient.value.localizedStandardContains(text)
                    }) == true
                    || (recipe.categories?.contains { category in
                        category.value.localizedStandardContains(text)
                    }) == true
            }
        }
    }
}

/// Convenience descriptors for `Recipe` queries.
public extension FetchDescriptor where T == Recipe {
    /// Builds a fetch descriptor for recipe queries.
    static func recipes(_ predicate: RecipePredicate, order: SortOrder = .forward) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.name, order: order)
            ]
        )
    }
}
