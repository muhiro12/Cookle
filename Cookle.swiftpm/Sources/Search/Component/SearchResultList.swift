//
//  SearchResultList.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftData
import SwiftUI

struct SearchResultList: View {
    @Query private var recipes: [Recipe]
    @Query private var ingredients: [Ingredient]
    @Query private var categories: [Category]

    @Binding private var recipe: Recipe?

    @State private var searchText = ""

    init(searchText: String, selection: Binding<Recipe?> = .constant(nil)) {
        _recipe = selection
        _recipes = .init(.recipes(.nameContains(searchText)))
        _ingredients = .init(.ingredients(.valueContains(searchText)))
        _categories = .init(.categories(.valueContains(searchText)))
    }

    var body: some View {
        List(
            Array(
                Set(
                    recipes
                        + ingredients.flatMap { $0.recipes.orEmpty }
                        + categories.flatMap { $0.recipes.orEmpty }
                )
            ),
            id: \.self,
            selection: $recipe
        ) { recipe in
            NavigationLink(value: recipe) {
                Text(recipe.name)
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        SearchResultList(searchText: "a")
    }
}
