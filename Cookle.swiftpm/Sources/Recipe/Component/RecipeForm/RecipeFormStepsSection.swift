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
                        .frame(width: 24)
                    TextField(
                        text: .init(
                            get: {
                                guard index < steps.endIndex else {
                                    return ""
                                }
                                return steps[index]
                            },
                            set: { value in
                                guard index < steps.endIndex else {
                                    return
                                }
                                steps[index] = value
                                guard !value.isEmpty,
                                      !steps.contains("") else {
                                    return
                                }
                                steps.append("")
                            }
                        ),
                        axis: .vertical
                    ) {
                        Text("Step")
                    }
                }
            }
            .onMove {
                steps.move(fromOffsets: $0, toOffset: $1)
            }
            .onDelete {
                steps.remove(atOffsets: $0)
                guard steps.isEmpty else {
                    return
                }
                steps.append("")
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
