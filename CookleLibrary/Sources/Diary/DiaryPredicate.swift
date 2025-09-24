//
//  DiaryPredicate.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

/// Predicates describing how to filter `Diary` records.
public enum DiaryPredicate {
    case all
    case none

    /// Concrete SwiftData predicate for this case.
    public var value: Predicate<Diary> {
        switch self {
        case .all:
            .true
        case .none:
            .false
        }
    }
}

/// Convenience descriptors for `Diary` queries.
public extension FetchDescriptor where T == Diary {
    static func diaries(_ predicate: DiaryPredicate, order: SortOrder = .reverse) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.date, order: order)
            ]
        )
    }
}
