//
//  TagPredicate.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/23/24.
//

import Foundation
import SwiftData

/// Query cases used to build SwiftData predicates for tag fetches.
nonisolated public enum TagPredicate<T: Tag> {
    /// Includes every tag record in the fetch.
    case all
    /// Excludes every tag record from the fetch.
    case none // swiftlint:disable:this discouraged_none_name
    /// Includes only tags whose stored value exactly equals the supplied text.
    case valueIs(String)
    /// Includes tags whose value contains the supplied text or its kana-normalized forms.
    case valueContains(String)

    /// SwiftData predicate that preserves the semantics of the selected query case.
    public var value: Predicate<T> {
        switch self {
        case .all:
            return .true
        case .none:
            return .false
        case .valueIs(let value):
            return #Predicate<T> { tag in
                tag.value == value
            }
        case .valueContains(let value):
            let hiragana = Self.hiragana(for: value)
            let katakana = Self.katakana(for: value)
            return #Predicate<T> { tag in
                tag.value.localizedStandardContains(value)
                    || tag.value.localizedStandardContains(hiragana)
                    || tag.value.localizedStandardContains(katakana)
            }
        }
    }
}

/// Fetch descriptor helpers for ingredient tag queries sorted by display value.
public extension FetchDescriptor where T == Ingredient {
    /// Builds an ingredient fetch descriptor using the supplied predicate and sort order.
    static func ingredients(
        _ predicate: TagPredicate<Ingredient>,
        order: SortOrder = .forward
    ) -> FetchDescriptor<Ingredient> {
        .init(
            predicate: predicate.ingredientValue,
            sortBy: [
                .init(\.value, order: order)
            ]
        )
    }
}

public extension FetchDescriptor where T == Category {
    /// Builds a category fetch descriptor using the supplied predicate and sort order.
    static func categories(
        _ predicate: TagPredicate<Category>,
        order: SortOrder = .forward
    ) -> FetchDescriptor<Category> {
        .init(
            predicate: predicate.categoryValue,
            sortBy: [
                .init(\.value, order: order)
            ]
        )
    }
}

private extension TagPredicate {
    static func hiragana(for value: String) -> String {
        value.applyingTransform(.hiraganaToKatakana, reverse: true).orEmpty
    }

    static func katakana(for value: String) -> String {
        value.applyingTransform(.hiraganaToKatakana, reverse: false).orEmpty
    }
}

private extension TagPredicate where T == Ingredient {
    var ingredientValue: Predicate<Ingredient> {
        switch self {
        case .all:
            return .true
        case .none:
            return .false
        case .valueIs(let value):
            return #Predicate<Ingredient> { ingredient in
                ingredient.value == value
            }
        case .valueContains(let value):
            let hiragana = Self.hiragana(for: value)
            let katakana = Self.katakana(for: value)
            return #Predicate<Ingredient> { ingredient in
                ingredient.value.localizedStandardContains(value)
                    || ingredient.value.localizedStandardContains(hiragana)
                    || ingredient.value.localizedStandardContains(katakana)
            }
        }
    }
}

private extension TagPredicate where T == Category {
    var categoryValue: Predicate<Category> {
        switch self {
        case .all:
            return .true
        case .none:
            return .false
        case .valueIs(let value):
            return #Predicate<Category> { category in
                category.value == value
            }
        case .valueContains(let value):
            let hiragana = Self.hiragana(for: value)
            let katakana = Self.katakana(for: value)
            return #Predicate<Category> { category in
                category.value.localizedStandardContains(value)
                    || category.value.localizedStandardContains(hiragana)
                    || category.value.localizedStandardContains(katakana)
            }
        }
    }
}
