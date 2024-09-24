//
//  DiaryObjectPredicate.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

enum DiaryObjectPredicate {
    case all
    case none

    var value: Predicate<DiaryObject> {
        switch self {
        case .all:
            .true
        case .none:
            .false
        }
    }
}

extension FetchDescriptor where T == DiaryObject {
    static func diaryObjects(_ predicate: DiaryObjectPredicate, order: SortOrder = .reverse) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.modifiedTimestamp, order: order)
            ]
        )
    }
}
