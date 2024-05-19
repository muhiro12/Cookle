//
//  AddMultipleStepsButton.swift
//
//
//  Created by Hiromu Nakano on 2024/05/10.
//

import SwiftUI

struct AddMultipleStepsButton: View {
    @Binding private var steps: [String]

    @State private var isPresented = false
    @State private var text = ""

    init(steps: Binding<[String]>) {
        self._steps = steps
    }

    var body: some View {
        Button("Add Multiple Steps at Once") {
            isPresented = true
        }
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                TextEditor(text: $text)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                text = ""
                                isPresented = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                steps.insert(
                                    contentsOf: text.split(separator: "\n").map {
                                        String($0)
                                    },
                                    at: steps.lastIndex(of: "") ?? .zero
                                )
                                text = ""
                                isPresented = false
                            }
                        }
                    }
                    .padding()
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.separator)
                    }
                    .padding()
            }
            .interactiveDismissDisabled()
        }
    }
}

#Preview {
    AddMultipleStepsButton(steps: .constant([]))
}
