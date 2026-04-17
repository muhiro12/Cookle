//
//  AddMultipleStepsButton.swift
//
//
//  Created by Hiromu Nakano on 2024/05/10.
//

import SwiftUI

struct AddMultipleStepsButton: View {
    private enum Placeholder {
        static let steps: LocalizedStringKey = .init("Boil water in a large pot and add salt.\nCook the spaghetti until al dente.\nIn a separate pan, cook the pancetta until crispy.\nBeat the eggs in a bowl and mix with grated Parmesan cheese.\nDrain the spaghetti and mix with pancetta and the egg mixture.\nSeason with black pepper and serve immediately.") // swiftlint:disable:this line_length
    }

    @Binding private var steps: [String]

    @State private var isPresented = false

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
                placeholder: Placeholder.steps
            )
            .interactiveDismissDisabled()
        }
    }

    init(steps: Binding<[String]>) {
        self._steps = steps
    }
}

#Preview {
    AddMultipleStepsButton(steps: .constant([]))
}
