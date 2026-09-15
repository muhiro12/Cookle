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
    private let showsRecipeName: Bool

    var body: some View {
        Button {
            if let action {
                action()
            } else {
                isPresented = true
            }
        } label: {
            Label {
                if showsRecipeName {
                    Text("Duplicate \(recipe.name)")
                } else {
                    Text("Duplicate")
                }
            } icon: {
                Image(systemName: "document.on.document")
                    .accessibilityHidden(true)
            }
        }
        .sheet(isPresented: $isPresented) {
            RecipeFormNavigationView(type: .duplicate)
        }
    }

    init(showsRecipeName: Bool = true, action: (() -> Void)? = nil) {
        self.showsRecipeName = showsRecipeName
        self.action = action
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    DuplicateRecipeButton()
        .environment(recipes[.zero])
}
