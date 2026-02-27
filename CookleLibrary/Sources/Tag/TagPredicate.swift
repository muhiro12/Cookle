//
//  TagPredicate.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/23/24.
//

import Foundation
import SwiftData

/// Predicates describing how to filter tag models.
nonisolated public enum TagPredicate<T: Tag> {
    case all
    case none
    case valueIs(String)
    case valueContains(String)

    /// Concrete SwiftData predicate for this case.
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

/// Convenience descriptors for tag queries.
public extension FetchDescriptor where T == Ingredient {
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
    static func categories(_ predicate: TagPredicate<T>, order: SortOrder = .forward) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.value, order: order)
            ]
        )
    }
}
