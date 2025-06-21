//
//  RecipeCreatedAtSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI

struct RecipeCreatedAtSection: View {
    @Environment(RecipeEntity.self) private var recipe

    var body: some View {
        Section {
            Text(recipe.createdTimestamp.formatted(.dateTime.year().month().day()))
        } header: {
            Text("Created At")
        }
    }
}

#Preview {
    CooklePreview { preview in
        List {
            RecipeCreatedAtSection()
                .environment(RecipeEntity(preview.recipes[0])!)
        }
    }
}
