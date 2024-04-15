//
//  Tag.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import SwiftData

protocol Tag: PersistentModel, Comparable {
    var value: String { get }
    var recipes: [Recipe] { get }
    init(_ value: String)
}

extension Tag {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.value < rhs.value
    }
}
