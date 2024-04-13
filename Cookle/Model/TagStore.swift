//
//  TagStore.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import Foundation

@Observable
final class TagStore {
    private var tagList: [Tag] = []

    var nameTagList: [Tag] {
        tagList.filter { $0.type == .name }.sorted()
    }

    var yearTagList: [Tag] {
        tagList.filter { $0.type == .year }.sorted { $0 > $1 }
    }

    var yearMonthTagList: [Tag] {
        tagList.filter { $0.type == .yearMonth }.sorted { $0 > $1 }
    }

    var ingredientTagList: [Tag] {
        tagList.filter { $0.type == .ingredient }.sorted()
    }

    var instructionTagList: [Tag] {
        tagList.filter { $0.type == .instruction }.sorted()
    }

    var customTagList: [Tag] {
        tagList.filter { $0.type == .custom }.sorted()
    }

    func modify(_ recipes: [Recipe]) {
        tagList.removeAll()
        recipes.forEach(insert)
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

    private func insert(_ tag: Tag) {
        guard !tagList.contains(where: {
            $0.type == tag.type && $0.value == tag.value
        }) else {
            return
        }
        tagList.append(tag)
    }
}
