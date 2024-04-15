//
//  Ingredient.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import SwiftData

@Model
final class Ingredient: Tag {
    private(set) var value: String
    private(set) var recipes: [Recipe]

    init(_ value: String) {
        self.value = value
        self.recipes = []
    }
}
