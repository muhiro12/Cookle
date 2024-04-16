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
            Section("Ingredients") {
                ForEach(recipe.ingredients, id: \.self) {
                    Text($0.value)
                }
            }
            Section("Instructions") {
                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { values in
                    HStack(alignment: .top) {
                        Text(values.offset.description + ".")
                            .frame(width: 24)
                        Text(values.element)
                    }
                }
            }
            Section("Tags") {
                ForEach(recipe.categories, id: \.self) {
                    Text($0.value)
                }
            }
            Section("Diaries") {
                ForEach(recipe.diaries) {
                    Text($0.date.formatted(.dateTime.year().month().day()))
                }
            }
            Section("Update Date") {
                Text(recipe.updateDate.description)
            }
            Section("Creation Date") {
                Text(recipe.creationDate.description)
            }
        }
    }
}

#Preview {
    RecipeView()
        .environment(PreviewData.randomRecipe())
}
