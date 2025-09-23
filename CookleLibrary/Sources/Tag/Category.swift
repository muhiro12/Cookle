//
//  Category.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import SwiftData

@Model
public nonisolated final class Category: Tag {
    public private(set) var value = String.empty

    @Relationship(inverse: \Recipe.categories)
    public private(set) var recipes = [Recipe]?.some(.empty)

    public private(set) var createdTimestamp = Date.now
    public private(set) var modifiedTimestamp = Date.now

    private init() {}

    public static func create(context: ModelContext, value: String) -> Self {
        let category = (try? context.fetchFirst(.categories(.valueIs(value)))) ?? .init()
        context.insert(category)
        category.value = value
        return category as! Self
    }

    public func update(value: String) {
        self.value = value
        self.modifiedTimestamp = .now
    }
}

extension Category {
    public static var titleKey: String {
        "Categories"
    }

    public static func descriptor(_ predicate: TagPredicate<Category>, order: SortOrder) -> FetchDescriptor<Category> {
        .categories(predicate, order: order)
    }

    public static func descriptor(_ predicate: TagPredicate<Category>) -> FetchDescriptor<Category> {
        .categories(predicate)
    }
}
