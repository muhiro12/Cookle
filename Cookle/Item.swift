//
//  Item.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import Foundation
import SwiftData

@Model
final class Item {
    let name: String
    let tag: String

    init(name: String, tag: String) {
        self.name = name
        self.tag = tag
    }
}

@Observable
final class TagContext {
    private(set) var tags: [Tag] = []

    func insert(_ tag: Tag) {
        guard !tags.contains(where: { $0.name == tag.name }) else {
            return
        }
        tags.append(tag)
    }

    func modify(_ items: [Item]) {
        items.forEach {
            insert(.init(name: $0.tag))
        }
    }
}

final class Tag {
    let name: String

    init(name: String) {
        self.name = name
    }
}

extension Tag: Identifiable {}
