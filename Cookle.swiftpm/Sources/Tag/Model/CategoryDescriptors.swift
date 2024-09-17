//
//  CategoryDescriptors.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

extension Category {
    enum Predicate {
        case all
        case none
        case valueIs(String)

        var value: Foundation.Predicate<Category> {
            switch self {
            case .all:
                return .true
            case .none:
                return .false
            case .valueIs(let value):
                return #Predicate {
                    $0.value == value
                }
            }
        }
    }
}

extension FetchDescriptor where T == Category {
    static func categories(_ predicate: T.Predicate, order: SortOrder = .forward) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.value, order: order)
            ]
        )
    }
}