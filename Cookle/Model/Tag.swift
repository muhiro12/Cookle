//
//  Tag.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import Foundation

struct Tag {
    enum TagType {
        case name
        case year
        case yearMonth
        case ingredient
        case instruction
        case custom
    }

    let id = UUID()
    let type: TagType
    let value: String
}

extension Tag: Identifiable {}

extension Tag: Hashable {}
