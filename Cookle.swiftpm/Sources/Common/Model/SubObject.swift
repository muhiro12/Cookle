//
//  SubObject.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/30/24.
//

protocol SubObject: Comparable {
    var order: Int { get }
}

extension SubObject {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.order < rhs.order
    }
}
