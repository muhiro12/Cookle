//
//  PhotoPredicate.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import Foundation
import SwiftData

/// Query cases used to build SwiftData predicates for photo-asset fetches.
nonisolated public enum PhotoPredicate {
    /// Includes every photo asset in the fetch.
    case all
    /// Excludes every photo asset from the fetch.
    case none // swiftlint:disable:this discouraged_none_name
    /// Includes only photo assets created from the supplied source.
    case sourceIs(PhotoSource)
    /// Includes only photo assets whose binary data matches the supplied payload.
    case dataIs(Data)

    /// SwiftData predicate that preserves the semantics of the selected query case.
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

/// Fetch descriptor helpers for photo-asset queries sorted by recency.
public extension FetchDescriptor where T == Photo {
    /// Builds a photo-asset fetch descriptor using the supplied predicate and recency order.
    static func photos(_ predicate: PhotoPredicate, order: SortOrder = .reverse) -> FetchDescriptor {
        .init(
            predicate: predicate.value,
            sortBy: [
                .init(\.modifiedTimestamp, order: order)
            ]
        )
    }
}
