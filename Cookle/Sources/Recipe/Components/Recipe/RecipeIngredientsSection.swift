//
//  RecipeIngredientsSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftData
import SwiftUI

struct RecipeIngredientsSection: View {
    @Environment(Recipe.self) private var recipe

    var body: some View {
        if let objects = recipe.ingredientObjects,
           objects.isNotEmpty {
            Section {
                ForEach(objects.sorted()) { object in
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

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    List {
        RecipeIngredientsSection()
            .environment(recipes[0])
    }
}
