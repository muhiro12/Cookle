//
//  DiaryDescriptors.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

extension Diary {
    enum Predicate {
        case all
        case none

        var value: Foundation.Predicate<Diary> {
            switch self {
            case .all:
                .true
            case .none:
                .false
            }
        }
    }
}

extension FetchDescriptor where T == Diary {
    static func diaries(_ predicate: T.Predicate, order: SortOrder = .reverse) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.date, order: order)
            ]
        )
    }
}
