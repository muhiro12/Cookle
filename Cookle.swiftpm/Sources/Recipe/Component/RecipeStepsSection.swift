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
        if recipe.steps.isNotEmpty {
            Section {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { values in
                    HStack(alignment: .top) {
                        Text((values.offset + 1).description + ".")
                            .frame(width: 24)
                        Text(values.element)
                    }
                }
            } header: {
                Text("Steps")
            }
        }
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
