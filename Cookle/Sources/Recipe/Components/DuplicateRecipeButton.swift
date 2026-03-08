//
//  DuplicateRecipeButton.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 10/18/24.
//

import SwiftData
import SwiftUI

struct DuplicateRecipeButton: View {
    @Environment(Recipe.self)
    private var recipe

    @State private var isPresented = false

    private let action: (() -> Void)?

    var body: some View {
        Button {
            if let action {
                action()
            } else {
                isPresented = true
            }
        } label: {
            Label {
                Text("Duplicate \(recipe.name)")
            } icon: {
                Image(systemName: "document.on.document")
                    .accessibilityHidden(true)
            }
        }
        .sheet(isPresented: $isPresented) {
            RecipeFormNavigationView(type: .duplicate)
        }
    }

    init(action: (() -> Void)? = nil) {
        self.action = action
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    DuplicateRecipeButton()
        .environment(recipes[.zero])
}
