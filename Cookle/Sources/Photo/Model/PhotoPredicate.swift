//
//  PhotoPredicate.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

enum PhotoPredicate {
    case all
    case none
    case sourceIs(PhotoSource)
    case dataIs(Data)

    var value: Foundation.Predicate<Photo> {
        switch self {
        case .all:
            return .true
        case .none:
            return .false
        case .sourceIs(let source):
            let id = source.rawValue
            return #Predicate {
                $0.sourceID == id
            }
        case .dataIs(let data):
            return #Predicate {
                $0.data == data
            }
        }
    }
}

extension FetchDescriptor where T == Photo {
    static func photos(_ predicate: PhotoPredicate, order: SortOrder = .reverse) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.modifiedTimestamp, order: order)
            ]
        )
    }
}
