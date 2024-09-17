//
//  RecipeServingSizeSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI

struct RecipeServingSizeSection: View {
    @Environment(Recipe.self) private var recipe

    var body: some View {
        if recipe.servingSize.isNotZero {
            Section {
                Text(recipe.servingSize.description + " servings")
            } header: {
                Text("Serving Size")
            }
        }
    }
}

#Preview {
    CooklePreview { preview in
        List {
            RecipeServingSizeSection()
                .environment(preview.recipes[0])
        }
    }
}
