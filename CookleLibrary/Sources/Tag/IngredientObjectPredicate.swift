//
//  IngredientObjectPredicate.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

/// Predicates describing how to filter `IngredientObject` records.
public enum IngredientObjectPredicate {
    /// Matches every ingredient object.
    case all
    /// Matches no ingredient objects.
    case none // swiftlint:disable:this discouraged_none_name

    /// Concrete SwiftData predicate for this case.
    public var value: Foundation.Predicate<IngredientObject> {
        switch self {
        case .all:
            .true
        case .none:
            .false
        }
    }
}

public extension FetchDescriptor where T == IngredientObject {
    /// Builds a fetch descriptor for ingredient-object queries.
    static func ingredientObjects(
        _ predicate: IngredientObjectPredicate,
        order _: SortOrder = .reverse
    ) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.modifiedTimestamp, order: .reverse)
            ]
        )
    }
}
