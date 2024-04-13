//
//  Tag.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import Foundation

protocol Tag: Identifiable, Hashable, Comparable {
    var value: String { get }
}

extension Tag {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.value < rhs.value
    }
}
