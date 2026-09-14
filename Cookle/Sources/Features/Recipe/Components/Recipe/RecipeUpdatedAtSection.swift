//
//  RecipeUpdatedAtSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftData
import SwiftUI

struct RecipeUpdatedAtSection: View {
    @Environment(Recipe.self)
    private var recipe

    var presentation: RecipeSectionPresentation = .native

    var body: some View {
        RecipeContentSection("Updated At", presentation: presentation) {
            Text(recipe.modifiedTimestamp.formatted(.dateTime.year().month().day()))
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    List {
        RecipeUpdatedAtSection()
            .environment(recipes[0])
    }
}
