//
//  IngredientDescriptors.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

extension Ingredient {
    enum Predicate {
        case all
        case none

        var value: Foundation.Predicate<Ingredient> {
            switch self {
            case .all:
                .true
            case .none:
                .false
            }
        }
    }
}

extension FetchDescriptor where T == Ingredient {
    static func ingredients(_ predicate: T.Predicate, order: SortOrder = .forward) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.value, order: order)
            ]
        )
    }
}
