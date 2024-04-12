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
                ForEach(recipe.ingredientList, id: \.self) {
                    Text($0)
                }
            }
            Section("Instructions") {
                ForEach(Array(recipe.instructionList.enumerated()), id: \.offset) { values in
                    HStack(alignment: .top) {
                        Text(values.offset.description + ".")
                            .frame(width: 24)
                        Text(values.element)
                    }
                }
            }
            Section("Tags") {
                ForEach(recipe.tagList, id: \.self) {
                    Text($0)
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
