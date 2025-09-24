//
//  SubObject.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/30/24.
//

/// Ordered sub-entity used inside composite models.
public nonisolated protocol SubObject: Comparable {
    var order: Int { get }
}

public extension SubObject {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.order < rhs.order
    }
}
