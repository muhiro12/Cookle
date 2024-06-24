//
//  Category.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import Foundation
import SwiftData

@Model
final class Category: Tag {
    private(set) var value = String.empty
    @Relationship
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
    static var descriptor: FetchDescriptor<Category> {
        .init(
            sortBy: [
                .init(\.value)
            ]
        )
    }
}
