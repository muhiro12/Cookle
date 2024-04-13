//
//  Tag.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import Foundation

struct Tag {
    enum TagType: Int {
        case name = 3
        case yearMonth = 1
        case yearMonthDay = 0
        case ingredient = 4
        case instruction = 2
        case custom = 5
    }

    let id = UUID()
    let type: TagType
    let value: String
}

extension Tag: Identifiable {}

extension Tag: Hashable {}

extension Tag: Comparable {
    static func < (lhs: Tag, rhs: Tag) -> Bool {
        guard lhs.type == rhs.type else {
            return lhs.type.rawValue < rhs.type.rawValue
        }
        return lhs.value < rhs.value
    }
}
