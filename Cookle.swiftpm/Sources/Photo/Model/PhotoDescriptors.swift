//
//  PhotoDescriptors.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

extension Photo {
    enum Predicate {
        case all
        case none

        var value: Foundation.Predicate<Photo> {
            switch self {
            case .all:
                .true
            case .none:
                .false
            }
        }
    }
}

extension FetchDescriptor where T == Photo {
    static func photos(_ predicate: T.Predicate, order: SortOrder = .reverse) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.modifiedTimestamp, order: order)
            ]
        )
    }
}
