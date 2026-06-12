//
//  RecipeFormStepsSection.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/03.
//

import Foundation
import SwiftData
import SwiftUI

struct RecipeFormStepsSection: View {
    @Binding private var steps: [String]
    @FocusState private var focusedRowID: UUID?
    @State private var stepRowIDs: [UUID]

    var body: some View {
        Section {
            ForEach(stepRows) { row in
                HStack(alignment: .top) {
                    Text((row.index + RecipeStepLayout.stepNumberOffset).description + ".")
                        .foregroundStyle(.secondary)
                        .frame(width: RecipeStepLayout.indexWidth)
                    TextField(text: stepBinding(at: row.index), axis: .vertical) {
                        Text("Boil water in a large pot and add salt.")
                    }
                    .focused($focusedRowID, equals: row.id)
                }
            }
            .onMove { sourceOffsets, destinationOffset in
                moveSteps(
                    fromOffsets: sourceOffsets,
                    toOffset: destinationOffset
                )
            }
            .onDelete { offsets in
                deleteSteps(atOffsets: offsets)
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
        .onAppear {
            synchronizeStepRowIDs()
        }
        .onChange(of: steps) {
            normalizeSteps()
            synchronizeStepRowIDs()
        }
    }

    init(_ steps: Binding<[String]>) {
        self._steps = steps
        self._stepRowIDs = State(
            initialValue: RecipeFormStableRowIDs.make(
                count: steps.wrappedValue.count
            )
        )
    }
}

private extension RecipeFormStepsSection {
    var stepRows: [RecipeFormStableRowIDs.IndexedRow] {
        RecipeFormStableRowIDs.indexedRows(
            rowIDs: stepRowIDs,
            count: steps.count
        )
    }

    func stepBinding(at index: Int) -> Binding<String> {
        .init(
            get: {
                steps[index]
            },
            set: { value in
                steps[index] = value
            }
        )
    }

    func moveSteps(
        fromOffsets sourceOffsets: IndexSet,
        toOffset destinationOffset: Int
    ) {
        steps.move(
            fromOffsets: sourceOffsets,
            toOffset: destinationOffset
        )
        stepRowIDs.move(
            fromOffsets: sourceOffsets,
            toOffset: destinationOffset
        )
    }

    func deleteSteps(atOffsets offsets: IndexSet) {
        steps.remove(atOffsets: offsets)
        stepRowIDs.remove(atOffsets: offsets)
        clearStaleFocus()
    }

    func normalizeSteps() {
        let normalizedSteps = RecipeFormPlaceholderRows.normalizedStrings(
            steps
        )
        guard normalizedSteps != steps else {
            return
        }

        steps = normalizedSteps
    }

    func synchronizeStepRowIDs() {
        RecipeFormStableRowIDs.synchronize(
            &stepRowIDs,
            count: steps.count
        )
        clearStaleFocus()
    }

    func clearStaleFocus() {
        guard let focusedRowID,
              stepRowIDs.contains(focusedRowID) == false else {
            return
        }

        self.focusedRowID = nil
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
