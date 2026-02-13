//
//  RecipeCreatedAtSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftData
import SwiftUI

struct RecipeCreatedAtSection: View {
    @Environment(Recipe.self) private var recipe

    var body: some View {
        Section {
            Text(recipe.createdTimestamp.formatted(.dateTime.year().month().day()))
        } header: {
            Text("Created At")
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    List {
        RecipeCreatedAtSection()
            .environment(recipes[0])
    }
}
