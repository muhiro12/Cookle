//
//  IngredientObjectPredicate.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

/// Query cases used to build SwiftData predicates for ingredient-row fetches.
public enum IngredientObjectPredicate {
    /// Includes every ingredient row in the fetch.
    case all
    /// Excludes every ingredient row from the fetch.
    case none // swiftlint:disable:this discouraged_none_name

    /// SwiftData predicate that preserves the semantics of the selected query case.
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
    /// Builds an ingredient-row fetch descriptor sorted by most recently modified first.
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
