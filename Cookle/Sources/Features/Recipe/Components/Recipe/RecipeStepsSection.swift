//
//  RecipeStepsSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftData
import SwiftUI

struct RecipeStepsSection: View {
    @Environment(Recipe.self)
    private var recipe

    var body: some View {
        if !recipe.steps.isEmpty {
            Section {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { values in
                    HStack(alignment: .top) {
                        Text((values.offset + RecipeStepLayout.stepNumberOffset).description + ".")
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: true, vertical: false)
                        Text(values.element)
                    }
                }
            } header: {
                Text("Steps")
            }
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    List {
        RecipeStepsSection()
            .environment(recipes[0])
    }
}
