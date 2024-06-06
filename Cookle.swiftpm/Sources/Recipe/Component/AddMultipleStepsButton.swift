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

    init(steps: Binding<[String]>) {
        self._steps = steps
    }

    var body: some View {
        Button("Add Multiple Steps at Once") {
            isPresented = true
        }
        .sheet(isPresented: $isPresented) {
            AddMultipleTextsView(texts: $steps)
                .interactiveDismissDisabled()
        }
    }
}

#Preview {
    AddMultipleStepsButton(steps: .constant([]))
}
