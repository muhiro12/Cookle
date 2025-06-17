//
//  RecipeUpdatedAtSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI

struct RecipeUpdatedAtSection: View {
    @Environment(RecipeEntity.self) private var recipe

    var body: some View {
        Section {
            Text(recipe.modifiedTimestamp.formatted(.dateTime.year().month().day()))
        } header: {
            Text("Updated At")
        }
    }
}

#Preview {
    CooklePreview { preview in
        List {
            RecipeUpdatedAtSection()
                .environment(RecipeEntity(preview.recipes[0])!)
        }
    }
}
