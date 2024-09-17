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
        case dataIs(Data)

        var value: Foundation.Predicate<Photo> {
            switch self {
            case .all:
                return .true
            case .none:
                return .false
            case .dataIs(let data):
                return #Predicate {
                    $0.data == data
                }
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
