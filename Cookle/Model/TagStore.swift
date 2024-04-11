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
        guard !tags.contains(where: { $0.value == tag.value }) else {
            return
        }
        tags.append(tag)
    }

    func insert(with recipe: Recipe) {
        insert(.init(type: .name, value: recipe.name))
        insert(.init(type: .year, value: recipe.year))
        insert(.init(type: .yearMonth, value: recipe.yearMonth))
        recipe.ingredientList.forEach {
            insert(.init(type: .ingredient, value: $0))
        }
        recipe.instructionList.forEach {
            insert(.init(type: .instruction, value: $0))
        }
        recipe.tagList.forEach { tag in
            insert(.init(type: .custom, value: tag))
        }
    }

    func modify(_ recipes: [Recipe]) {
        recipes.forEach(insert)
    }
}
