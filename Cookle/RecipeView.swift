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
        ScrollView {
            VStack(spacing: 16) {
                VStack {
                    Text("image")
                        .font(.headline)
                    Text(recipe.imageList.description)
                }
                VStack {
                    Text("name")
                        .font(.headline)
                    Text(recipe.name)
                }
                VStack {
                    Text("ingredients")
                        .font(.headline)
                    Text(recipe.ingredientList.description)
                }
                VStack {
                    Text("instructions")
                        .font(.headline)
                    Text(recipe.instructionList.description)
                }
                VStack {
                    Text("tags")
                        .font(.headline)
                    Text(recipe.tagList.description)
                }
                VStack {
                    Text("updateDate")
                        .font(.headline)
                    Text(recipe.updateDate.description)
                }
                VStack {
                    Text("creationDate")
                        .font(.headline)
                    Text(recipe.creationDate.description)
                }
            }
            .padding()
        }
    }
}

#Preview {
    RecipeView()
        .environment(Recipe())
}
