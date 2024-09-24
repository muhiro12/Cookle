//
//  DiaryObjectDescriptors.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

extension DiaryObject {
    enum Predicate {
        case all
        case none

        var value: Foundation.Predicate<DiaryObject> {
            switch self {
            case .all:
                .true
            case .none:
                .false
            }
        }
    }
}

extension FetchDescriptor where T == DiaryObject {
    static func diaryObjects(_ predicate: T.Predicate, order: SortOrder = .reverse) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.modifiedTimestamp, order: order)
            ]
        )
    }
}
