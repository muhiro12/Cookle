//
//  PhotoObjectPredicate.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

public enum PhotoObjectPredicate {
    case all
    case none

    public var value: Foundation.Predicate<PhotoObject> {
        switch self {
        case .all:
            .true
        case .none:
            .false
        }
    }
}

public extension FetchDescriptor where T == PhotoObject {
    public static func photoObjects(_ predicate: PhotoObjectPredicate, order: SortOrder = .reverse) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.modifiedTimestamp, order: order)
            ]
        )
    }
}
