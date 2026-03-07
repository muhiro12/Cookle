//
//  DiaryPredicate.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

/// Query cases used to build SwiftData predicates for diary fetches.
public enum DiaryPredicate {
    /// Includes every diary in the fetch.
    case all
    /// Excludes every diary from the fetch.
    case none // swiftlint:disable:this discouraged_none_name

    /// SwiftData predicate that preserves the semantics of the selected query case.
    public var value: Predicate<Diary> {
        switch self {
        case .all:
            .true
        case .none:
            .false
        }
    }
}

/// Fetch descriptor helpers for diary queries sorted by diary date.
public extension FetchDescriptor where T == Diary {
    /// Builds a diary fetch descriptor using the supplied predicate and date order.
    static func diaries(_ predicate: DiaryPredicate, order: SortOrder = .reverse) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.date, order: order)
            ]
        )
    }
}
