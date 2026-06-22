//
//  RecipeNoteSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftData
import SwiftUI

struct RecipeNoteSection: View {
    @Environment(Recipe.self)
    private var recipe

    var body: some View {
        if !recipe.note.isEmpty {
            Section {
                Text(recipe.note)
            } header: {
                Text("Note")
            }
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    List {
        RecipeNoteSection()
            .environment(recipes[0])
    }
}
