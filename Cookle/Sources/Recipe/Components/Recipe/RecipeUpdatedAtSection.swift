//
//  RecipeUpdatedAtSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftData
import SwiftUI

struct RecipeUpdatedAtSection: View {
    @Environment(Recipe.self) private var recipe

    var body: some View {
        Section {
            Text(recipe.modifiedTimestamp.formatted(.dateTime.year().month().day()))
        } header: {
            Text("Updated At")
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    List {
        RecipeUpdatedAtSection()
            .environment(recipes[0])
    }
}
