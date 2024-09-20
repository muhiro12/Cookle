//
//  RecipeNoteSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI

struct RecipeNoteSection: View {
    @Environment(Recipe.self) private var recipe

    var body: some View {
        if recipe.note.isNotEmpty {
            Section {
                Text(recipe.note)
            } header: {
                Text("Note")
            }
        }
    }
}

#Preview {
    CooklePreview { preview in
        List {
            RecipeNoteSection()
                .environment(preview.recipes[0])
        }
    }
}
