//
//  Category.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import SwiftData
import SwiftUI

@Model
final class Category: Tag {
    private(set) var value = String.empty

    @Relationship(inverse: \Recipe.categories)
    private(set) var recipes = [Recipe]?.some(.empty)

    private(set) var createdTimestamp = Date.now
    private(set) var modifiedTimestamp = Date.now

    private init() {}

    static func create(context: ModelContext, value: String) -> Self {
        let category: Category = (try? context.fetch(.init(predicate: #Predicate { $0.value == value })).first) ?? .init()
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

    static var descriptor: FetchDescriptor<Category> {
        .categories()
    }

    var selectionValue: CookleSelectionValue {
        .category(self)
    }
}

extension FetchDescriptor {
    static func categories(order: SortOrder = .forward) -> FetchDescriptor<Category> {
        .init(
            sortBy: [
                .init(\.value, order: order)
            ]
        )
    }
}
