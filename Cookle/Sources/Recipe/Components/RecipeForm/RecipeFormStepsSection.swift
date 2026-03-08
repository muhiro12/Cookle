//
//  RecipeFormStepsSection.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/03.
//

import SwiftData
import SwiftUI

struct RecipeFormStepsSection: View {
    private enum Layout {
        static let stepNumberOffset = Int("1") ?? .zero
        static let indexWidth = CGFloat(Int("24") ?? .zero)
    }

    @Binding private var steps: [String]

    var body: some View {
        Section {
            ForEach(steps.indices, id: \.self) { index in
                HStack(alignment: .top) {
                    Text((index + Layout.stepNumberOffset).description + ".")
                        .foregroundStyle(.secondary)
                        .frame(width: Layout.indexWidth)
                    TextField(text: $steps[index], axis: .vertical) {
                        Text("Boil water in a large pot and add salt.")
                    }
                }
            }
            .onMove { sourceOffsets, destinationOffset in
                steps.move(fromOffsets: sourceOffsets, toOffset: destinationOffset)
            }
            .onDelete { offsets in
                steps.remove(atOffsets: offsets)
            }
        } header: {
            HStack {
                Text("Steps")
                Spacer()
                AddMultipleStepsButton(steps: $steps)
                    .font(.caption)
                    .textCase(nil)
            }
        }
        .onChange(of: steps) {
            steps.removeAll { step in
                step.isEmpty
            }
            steps.append(.empty)
        }
    }

    init(_ steps: Binding<[String]>) {
        self._steps = steps
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    Form { () -> RecipeFormStepsSection in
        RecipeFormStepsSection(
            .constant(recipes[0].steps + [""])
        )
    }
}
