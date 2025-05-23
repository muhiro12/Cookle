//
//  IngredientObjectPredicate.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

enum IngredientObjectPredicate {
    case all
    case none

    var value: Foundation.Predicate<IngredientObject> {
        switch self {
        case .all:
            .true
        case .none:
            .false
        }
    }
}

extension FetchDescriptor where T == IngredientObject {
    static func ingredientObjects(_ predicate: IngredientObjectPredicate, order _: SortOrder = .reverse) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.modifiedTimestamp, order: .reverse)
            ]
        )
    }
}
