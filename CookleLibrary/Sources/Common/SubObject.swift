//
//  SubObject.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/30/24.
//

/// Contract for child models that participate in an ordered parent-owned collection.
nonisolated public protocol SubObject: Comparable {
    var order: Int { get }
}

public extension SubObject {
    /// Sorts sub-objects by their stored display order.
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.order < rhs.order
    }
}
