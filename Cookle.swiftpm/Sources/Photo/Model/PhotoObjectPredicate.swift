//
//  PhotoObjectPredicate.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

enum PhotoObjectPredicate {
    case all
    case none

    var value: Foundation.Predicate<PhotoObject> {
        switch self {
        case .all:
            .true
        case .none:
            .false
        }
    }
}

extension FetchDescriptor where T == PhotoObject {
    static func photoObjects(_ predicate: PhotoObjectPredicate, order: SortOrder = .reverse) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.modifiedTimestamp, order: order)
            ]
        )
    }
}
