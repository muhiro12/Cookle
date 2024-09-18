//
//  RecipeDescriptors.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

extension Recipe {
    enum Predicate {
        case all
        case none
        case idIs(ID)
        case nameContains(String)

        var value: Foundation.Predicate<Recipe> {
            switch self {
            case .all:
                return .true
            case .none:
                return .false
            case .idIs(let id):
                return #Predicate {
                    $0.persistentModelID == id
                }
            case .nameContains(let name):
                return #Predicate {
                    $0.name.localizedStandardContains(name)
                }
            }
        }
    }
}

extension FetchDescriptor where T == Recipe {
    static func recipes(_ predicate: T.Predicate, order: SortOrder = .forward) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.name, order: order)
            ]
        )
    }
}
