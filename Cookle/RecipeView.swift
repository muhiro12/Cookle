//
//  RecipeView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import SwiftUI
import SwiftData

struct RecipeView: View {
    @Environment(Recipe.self) var recipe

    var body: some View {
        List {
            Section("Categories") {
                ForEach(recipe.categories, id: \.self) {
                    Text($0.value)
                }
            }
            Section("Serving Size") {
                Text(recipe.servingSize.description + " servings")
            }
            Section("Cooking Time") {
                Text(recipe.cookingTime.description + " minutes")
            }
            Section("Ingredients") {
                ForEach(recipe.ingredients, id: \.self) {
                    Text($0.value)
                }
            }
            Section("Steps") {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { values in
                    HStack(alignment: .top) {
                        Text(values.offset.description + ".")
                            .frame(width: 24)
                        Text(values.element)
                    }
                }
            }
            Section("Updated At") {
                Text(recipe.updatedAt.description)
            }
            Section("Created At") {
                Text(recipe.createdAt.description)
            }
            Section("Diaries") {
                ForEach(recipe.diaries) {
                    Text($0.date.formatted(.dateTime.year().month().day()))
                }
            }
        }
    }
}

#Preview {
    RecipeView()
        .environment(PreviewData.randomRecipe())
}
