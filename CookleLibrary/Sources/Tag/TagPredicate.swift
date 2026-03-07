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
            let hiragana = value.applyingTransform(.hiraganaToKatakana, reverse: true).orEmpty
            let katakana = value.applyingTransform(.hiraganaToKatakana, reverse: false).orEmpty
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
    static func ingredients(_ predicate: TagPredicate<T>, order: SortOrder = .forward) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.value, order: order)
            ]
        )
    }
}

public extension FetchDescriptor where T == Category {
    /// Builds a category fetch descriptor using the supplied predicate and sort order.
    static func categories(_ predicate: TagPredicate<T>, order: SortOrder = .forward) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.value, order: order)
            ]
        )
    }
}
