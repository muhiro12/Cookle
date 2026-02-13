//
//  RecipeCookingTimeSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftData
import SwiftUI

struct RecipeCookingTimeSection: View {
    @Environment(Recipe.self) private var recipe

    var body: some View {
        Section {
            Text(recipe.cookingTime.description + " minutes")
        } header: {
            Text("Cooking Time")
        }
        .hidden(recipe.cookingTime.isZero)
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    List {
        RecipeCookingTimeSection()
            .environment(recipes[0])
    }
}
