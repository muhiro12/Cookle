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
            Section("Serving Size") {
                Text(recipe.servingSize.description + " servings")
            }
            Section("Cooking Time") {
                Text(recipe.cookingTime.description + " minutes")
            }
            Section("Ingredients") {
                ForEach(recipe.ingredientObjects, id: \.self) { ingredientObject in
                    HStack {
                        Text(ingredientObject.ingredient.value)
                        Spacer()
                        Text(ingredientObject.amount)
                    }
                }
            }
            Section("Steps") {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { values in
                    HStack(alignment: .top) {
                        Text((values.offset + 1).description + ".")
                            .frame(width: 24)
                        Text(values.element)
                    }
                }
            }
            Section("Categories") {
                ForEach(recipe.categories, id: \.self) {
                    Text($0.value)
                }
            }
            Section("Diaries") {
                ForEach(recipe.breakfasts + recipe.lunches + recipe.dinners) {
                    Text($0.date.formatted(.dateTime.year().month().day()))
                }
            }
            Section("Updated At") {
                Text(recipe.updatedAt.description)
            }
            Section("Created At") {
                Text(recipe.createdAt.description)
            }
        }
    }
}

#Preview {
    ModelContainerPreview { preview in
        RecipeView()
            .environment(preview.recipes[0])
    }
}
