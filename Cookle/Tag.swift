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
        case category
        case year
        case yearMonth
    }

    let id = UUID()
    let type: TagType
    let name: String
}

extension Tag: Identifiable {}

extension Tag: Hashable {}
