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
                    Text("name")
                        .font(.headline)
                    Text(recipe.name)
                }
                VStack {
                    Text("summary")
                        .font(.headline)
                    Text(recipe.summary)
                }
                VStack {
                    Text("tag")
                        .font(.headline)
                    Text(recipe.tag)
                }
                VStack {
                    Text("ingredients")
                        .font(.headline)
                    Text(recipe.ingredients.description)
                }
                VStack {
                    Text("instructions")
                        .font(.headline)
                    Text(recipe.instructions.description)
                }
                VStack {
                    Text("image")
                        .font(.headline)
                    Text(recipe.image?.description ?? "")
                }
                VStack {
                    Text("creationDate")
                        .font(.headline)
                    Text(recipe.creationDate.description)
                }
                VStack {
                    Text("updateDate")
                        .font(.headline)
                    Text(recipe.updateDate.description)
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
