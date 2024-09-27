//
//  RecipeIngredientsSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI

struct RecipeIngredientsSection: View {
    @Environment(Recipe.self) private var recipe

    var body: some View {
        if let objects = recipe.ingredientObjects,
           objects.isNotEmpty {
            Section {
                ForEach(objects.sorted { $0.order < $1.order }) { object in
                    HStack {
                        Text(object.ingredient?.value ?? "")
                        Spacer()
                        Text(object.amount)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Ingredients")
            }
        }
    }
}

#Preview {
    List {
        CooklePreview { preview in
            RecipeIngredientsSection()
                .environment(preview.recipes[0])
        }
    }
}
