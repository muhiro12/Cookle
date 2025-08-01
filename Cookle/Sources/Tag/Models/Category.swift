//
//  Category.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import SwiftData
import SwiftUI

@Model
nonisolated final class Category: Tag {
    private(set) var value = String.empty

    @Relationship(inverse: \Recipe.categories)
    private(set) var recipes = [Recipe]?.some(.empty)

    private(set) var createdTimestamp = Date.now
    private(set) var modifiedTimestamp = Date.now

    private init() {}

    static func create(context: ModelContext, value: String) -> Self {
        let category = (try? context.fetchFirst(.categories(.valueIs(value)))) ?? .init()
        context.insert(category)
        category.value = value
        return category as! Self
    }

    func update(value: String) {
        self.value = value
        self.modifiedTimestamp = .now
    }
}

extension Category {
    static var title: LocalizedStringKey {
        "Categories"
    }

    static func descriptor(_ predicate: TagPredicate<Category>, order: SortOrder) -> FetchDescriptor<Category> {
        .categories(predicate, order: order)
    }

    static func descriptor(_ predicate: TagPredicate<Category>) -> FetchDescriptor<Category> {
        .categories(predicate)
    }
}
