//
//  RecipeStepsSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftData
import SwiftUI

struct RecipeStepsSection: View {
    private enum Layout {
        static let stepNumberOffset = Int("1") ?? .zero
        static let indexWidth = CGFloat(Int("24") ?? .zero)
    }

    @Environment(Recipe.self)
    private var recipe

    var body: some View {
        Section {
            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { values in
                HStack(alignment: .top) {
                    Text((values.offset + Layout.stepNumberOffset).description + ".")
                        .foregroundStyle(.secondary)
                        .frame(width: Layout.indexWidth)
                    Text(values.element)
                }
            }
        } header: {
            Text("Steps")
        }
        .hidden(recipe.steps.isEmpty)
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    List {
        RecipeStepsSection()
            .environment(recipes[0])
    }
}
