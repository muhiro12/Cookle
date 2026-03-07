//
//  RecipePredicate.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

/// Query cases used to build SwiftData predicates for recipe fetches.
nonisolated public enum RecipePredicate {
    /// Includes every recipe in the fetch.
    case all
    /// Excludes every recipe from the fetch.
    case none // swiftlint:disable:this discouraged_none_name
    /// Includes only the recipe with the supplied persistent identifier.
    case idIs(Recipe.ID)
    /// Includes recipes whose name contains the supplied text or its kana-normalized forms.
    case nameContains(String)
    /// Includes recipes whose name, ingredient labels, or category labels match the supplied search text.
    case anyTextMatches(String)

    private static let shortTextThreshold = Int("3") ?? .zero

    /// SwiftData predicate that preserves the semantics of the selected query case.
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

/// Fetch descriptor helpers for recipe queries sorted by recipe name.
public extension FetchDescriptor where T == Recipe {
    /// Builds a recipe fetch descriptor using the supplied predicate and name sort order.
    static func recipes(_ predicate: RecipePredicate, order: SortOrder = .forward) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.name, order: order)
            ]
        )
    }
}
