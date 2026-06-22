//
//  RecipeServingSizeSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftData
import SwiftUI

struct RecipeServingSizeSection: View {
    @Environment(Recipe.self)
    private var recipe

    var body: some View {
        if recipe.servingSize != .zero {
            Section {
                Text(recipe.servingSize.description + " servings")
            } header: {
                Text("Serving Size")
            }
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    List {
        RecipeServingSizeSection()
            .environment(recipes[0])
    }
}
