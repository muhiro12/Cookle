//
//  RecipeCookingTimeSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftData
import SwiftUI

struct RecipeCookingTimeSection: View {
    @Environment(Recipe.self)
    private var recipe

    var presentation: RecipeSectionPresentation = .native

    var body: some View {
        if recipe.cookingTime != .zero {
            RecipeContentSection("Cooking Time", presentation: presentation) {
                Text(recipe.cookingTime.description + " minutes")
            }
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    List {
        RecipeCookingTimeSection()
            .environment(recipes[0])
    }
}
