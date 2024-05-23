//
//  Category.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import SwiftUI
import SwiftData

@Model
final class Category: Tag {
    private(set) var value: String!
    private(set) var recipes: [Recipe]!

    private init() {
        self.value = ""
        self.recipes = []
    }

    static func create(context: ModelContext, value: String) -> Self {
        let category: Category = (try? context.fetch(.init(predicate: #Predicate { $0.value == value })).first) ?? .init()
        context.insert(category)
        category.value = value
        return category as! Self
    }

    func update(value: String) {
        self.value = value
    }
}

extension Category {
    static var descriptor: FetchDescriptor<Category> {
        .init(
            sortBy: [
                .init(\.value)
            ]
        )
    }
}
