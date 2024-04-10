//
//  TagStore.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import Foundation

@Observable
final class TagStore {
    private(set) var tags: [Tag] = []

    func insert(_ tag: Tag) {
        guard !tags.contains(where: { $0.name == tag.name }) else {
            return
        }
        tags.append(tag)
    }

    func modify(_ recipes: [Recipe]) {
        recipes.forEach { recipe in
            insert(.init(type: .name, name: recipe.name))
            insert(.init(type: .category, name: recipe.tag))
            insert(.init(type: .year, name: recipe.year))
            insert(.init(type: .yearMonth, name: recipe.yearMonth))
        }
    }
}
