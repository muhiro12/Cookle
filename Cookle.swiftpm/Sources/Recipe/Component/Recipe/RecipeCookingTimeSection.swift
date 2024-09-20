//
//  RecipeCookingTimeSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI

struct RecipeCookingTimeSection: View {
    @Environment(Recipe.self) private var recipe

    var body: some View {
        if recipe.cookingTime.isNotZero {
            Section {
                Text(recipe.cookingTime.description + " minutes")
            } header: {
                Text("Cooking Time")
            }
        }
    }
}

#Preview {
    CooklePreview { preview in
        List {
            RecipeCookingTimeSection()
                .environment(preview.recipes[0])
        }
    }
}
