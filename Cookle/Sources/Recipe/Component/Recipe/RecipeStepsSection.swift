//
//  RecipeStepsSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI

struct RecipeStepsSection: View {
    @Environment(Recipe.self) private var recipe

    var body: some View {
        Section {
            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { values in
                HStack(alignment: .top) {
                    Text((values.offset + 1).description + ".")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    Text(values.element)
                }
            }
        } header: {
            Text("Steps")
        }
        .hidden(recipe.steps.isEmpty)
    }
}

#Preview {
    CooklePreview { preview in
        List {
            RecipeStepsSection()
                .environment(preview.recipes[0])
        }
    }
}
