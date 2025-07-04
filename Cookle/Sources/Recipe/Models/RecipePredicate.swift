//
//  RecipePredicate.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

nonisolated enum RecipePredicate {
    case all
    case none
    case idIs(Recipe.ID)
    case nameContains(String)

    var value: Predicate<Recipe> {
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
        }
    }
}

nonisolated extension FetchDescriptor where T == Recipe {
    static func recipes(_ predicate: RecipePredicate, order: SortOrder = .forward) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.name, order: order)
            ]
        )
    }
}
