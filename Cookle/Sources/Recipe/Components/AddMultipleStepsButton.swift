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
        Button {
            isPresented = true
        } label: {
            Text("Add Multiple Steps at Once")
        }
        .sheet(isPresented: $isPresented) {
            AddMultipleTextsNavigationView(
                texts: $steps,
                title: "Steps",
                placeholder: """
                             Boil water in a large pot and add salt.
                             Cook the spaghetti until al dente.
                             In a separate pan, cook the pancetta until crispy.
                             Beat the eggs in a bowl and mix with grated Parmesan cheese.
                             Drain the spaghetti and mix with pancetta and the egg mixture.
                             Season with black pepper and serve immediately.
                             """
            )
            .interactiveDismissDisabled()
        }
    }
}

#Preview {
    AddMultipleStepsButton(steps: .constant([]))
}
