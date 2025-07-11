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
        Section {
            Text(recipe.note)
        } header: {
            Text("Note")
        }
        .hidden(recipe.note.isEmpty)
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
