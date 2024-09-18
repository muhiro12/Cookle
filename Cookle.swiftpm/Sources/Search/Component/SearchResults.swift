//
//  SearchResults.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftData
import SwiftUI

struct SearchResults: View {
    @Query private var recipes: [Recipe]
    @Query private var ingredients: [Ingredient]
    @Query private var categories: [Category]

    init(searchText: String) {
        _recipes = .init(.recipes(.nameContains(searchText)))
        _ingredients = .init(.ingredients(.valueContains(searchText)))
        _categories = .init(.categories(.valueContains(searchText)))
    }

    var body: some View {
        ForEach(
            Array(
                Set(
                    recipes
                        + ingredients.flatMap { $0.recipes.orEmpty }
                        + categories.flatMap { $0.recipes.orEmpty }
                )
            )
        ) { recipe in
            NavigationLink(value: recipe) {
                Text(recipe.name)
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        SearchResults(searchText: "a")
    }
}
