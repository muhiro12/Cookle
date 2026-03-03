//
//  PhotoPredicate.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

/// Predicates describing how to filter `Photo` records.
nonisolated public enum PhotoPredicate {
    /// Matches every photo.
    case all
    /// Matches no photos.
    case none
    /// Matches photos created from the supplied source.
    case sourceIs(PhotoSource)
    /// Matches photos whose binary data equals the supplied payload.
    case dataIs(Data)

    /// Concrete SwiftData predicate for this case.
    public var value: Foundation.Predicate<Photo> {
        switch self {
        case .all:
            return .true
        case .none:
            return .false
        case .sourceIs(let source):
            let id = source.rawValue
            return #Predicate<Photo> { photo in
                photo.sourceID == id
            }
        case .dataIs(let data):
            return #Predicate<Photo> { photo in
                photo.data == data
            }
        }
    }
}

/// Convenience descriptors for `Photo` queries.
public extension FetchDescriptor where T == Photo {
    /// Builds a fetch descriptor for photo queries.
    static func photos(_ predicate: PhotoPredicate, order: SortOrder = .reverse) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.modifiedTimestamp, order: order)
            ]
        )
    }
}
