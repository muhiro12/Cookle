//
//  DiaryObjectPredicate.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

/// Query cases used to build SwiftData predicates for meal-row fetches.
public enum DiaryObjectPredicate {
    /// Includes every meal row in the fetch.
    case all
    /// Excludes every meal row from the fetch.
    case none // swiftlint:disable:this discouraged_none_name

    /// SwiftData predicate that preserves the semantics of the selected query case.
    public var value: Predicate<DiaryObject> {
        switch self {
        case .all:
            .true
        case .none:
            .false
        }
    }
}

public extension FetchDescriptor where T == DiaryObject {
    /// Builds a meal-row fetch descriptor sorted by most recently modified first.
    static func diaryObjects(_ predicate: DiaryObjectPredicate, order: SortOrder = .reverse) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.modifiedTimestamp, order: order)
            ]
        )
    }
}
