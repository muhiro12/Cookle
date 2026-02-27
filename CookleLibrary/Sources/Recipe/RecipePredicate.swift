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
    case all
    case none
    case idIs(Recipe.ID)
    case nameContains(String)
    /// Name OR ingredient OR category matches. For short text (<3), tags use equality; otherwise contains.
    case anyTextMatches(String)

    /// Concrete SwiftData predicate for this case.
    public var value: Predicate<Recipe> {
        switch self {
        case .all:
            return .true
        case .none:
            return .false
        case .idIs(let id):
            return #Predicate {
                $0.persistentModelID == id
            }
        case .nameContains(let name):
            let hiragana = name.applyingTransform(.hiraganaToKatakana, reverse: true).orEmpty
            let katakana = name.applyingTransform(.hiraganaToKatakana, reverse: false).orEmpty
            return #Predicate {
                $0.name.localizedStandardContains(name)
                    || $0.name.localizedStandardContains(hiragana)
                    || $0.name.localizedStandardContains(katakana)
            }
        case .anyTextMatches(let text):
            if text.count < 3 {
                return #Predicate {
                    $0.name.localizedStandardContains(text)
                        || ($0.ingredients?.contains { $0.value == text }) == true
                        || ($0.categories?.contains { $0.value == text }) == true
                }
            }
            return #Predicate {
                $0.name.localizedStandardContains(text)
                    || ($0.ingredients?.contains { $0.value.localizedStandardContains(text) }) == true
                    || ($0.categories?.contains { $0.value.localizedStandardContains(text) }) == true
            }
        }
    }
}

/// Convenience descriptors for `Recipe` queries.
public extension FetchDescriptor where T == Recipe {
    static func recipes(_ predicate: RecipePredicate, order: SortOrder = .forward) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.name, order: order)
            ]
        )
    }
}
