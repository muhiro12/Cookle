//
//  RecipeFormStepsSection.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/03.
//

import SwiftUI

struct RecipeFormStepsSection: View {
    @Binding private var steps: [String]

    init(_ steps: Binding<[String]>) {
        self._steps = steps
    }

    var body: some View {
        Section {
            ForEach(steps.indices, id: \.self) { index in
                HStack(alignment: .top) {
                    Text((index + 1).description + ".")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    TextField(text: $steps[index], axis: .vertical) {
                        Text("Boil water in a large pot and add salt.")
                    }
                }
            }
            .onMove {
                steps.move(fromOffsets: $0, toOffset: $1)
            }
            .onDelete {
                steps.remove(atOffsets: $0)
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
            steps.removeAll {
                $0.isEmpty
            }
            steps.append(.empty)
        }
    }
}

#Preview {
    CooklePreview { preview in
        Form { () -> RecipeFormStepsSection in
            RecipeFormStepsSection(
                .constant(preview.recipes[0].steps + [""])
            )
        }
    }
}
