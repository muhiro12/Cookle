//
//  Category.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import Foundation
import SwiftData
import SwiftUI

/// Category tag model.
@Model
nonisolated public final class Category: Tag {
    /// Category display value.
    public private(set) var value = String.empty

    @Relationship(inverse: \Recipe.categories)
    /// Recipes linked to this category.
    public private(set) var recipes = [Recipe]?.some(.empty)

    /// Creation timestamp.
    public private(set) var createdTimestamp = Date.now
    /// Last modification timestamp.
    public private(set) var modifiedTimestamp = Date.now

    private init() {}

    /// Creates (or returns) a category with the given value.
    public static func create(context: ModelContext, value: String) -> Self {
        if let existingCategory = try? context.fetchFirst(.categories(.valueIs(value))),
           let category = existingCategory as? Self {
            return category
        }

        let category: Self = .init()
        context.insert(category)
        category.value = value
        return category
    }

    /// Updates the category value.
    public func update(value: String) {
        self.value = value
        self.modifiedTimestamp = .now
    }
}

extension Category {
    /// Localized title used in UI.
    public static var title: LocalizedStringKey {
        "Categories"
    }

    /// Convenience descriptor with explicit order.
    public static func descriptor(_ predicate: TagPredicate<Category>, order: SortOrder) -> FetchDescriptor<Category> {
        .categories(predicate, order: order)
    }

    /// Convenience descriptor with default order.
    public static func descriptor(_ predicate: TagPredicate<Category>) -> FetchDescriptor<Category> {
        .categories(predicate)
    }
}
