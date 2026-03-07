//
//  Category.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import Foundation
import SwiftData
import SwiftUI

/// Persisted category tag used to group and filter recipes.
@Model
nonisolated public final class Category: Tag {
    /// Canonical category label shown in forms, filters, and recipe detail.
    public private(set) var value = String.empty

    /// Recipes currently assigned to this category.
    @Relationship(inverse: \Recipe.categories)
    public private(set) var recipes = [Recipe]?.some(.empty)

    /// Timestamp captured when the category is first inserted.
    public private(set) var createdTimestamp = Date.now
    /// Timestamp refreshed whenever the category label changes.
    public private(set) var modifiedTimestamp = Date.now

    private init() {
        // SwiftData-managed initializer.
    }

    /// Returns an existing category for `value`, or inserts a new one when needed.
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

    /// Replaces the stored category label and refreshes `modifiedTimestamp`.
    public func update(value: String) {
        self.value = value
        self.modifiedTimestamp = .now
    }
}

public extension Category {
    /// Localized section title shown anywhere category collections are presented.
    static var title: LocalizedStringKey {
        "Categories"
    }

    /// Builds a category fetch descriptor with an explicit sort order.
    static func descriptor(
        _ predicate: TagPredicate<Category>,
        order: SortOrder
    ) -> FetchDescriptor<Category> {
        .categories(predicate, order: order)
    }

    /// Builds a category fetch descriptor using the default sort order.
    static func descriptor(
        _ predicate: TagPredicate<Category>
    ) -> FetchDescriptor<Category> {
        .categories(predicate)
    }
}
