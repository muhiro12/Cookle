//
//  DiaryObjectPredicate.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

/// Predicates describing how to filter `DiaryObject` records.
public enum DiaryObjectPredicate {
    /// Matches every diary object.
    case all
    /// Matches no diary objects.
    case none // swiftlint:disable:this discouraged_none_name

    /// Concrete SwiftData predicate for this case.
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
    /// Builds a fetch descriptor for diary-object queries.
    static func diaryObjects(_ predicate: DiaryObjectPredicate, order: SortOrder = .reverse) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.modifiedTimestamp, order: order)
            ]
        )
    }
}
