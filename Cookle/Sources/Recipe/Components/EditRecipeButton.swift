//
//  EditRecipeButton.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/13.
//

import SwiftData
import SwiftUI

struct EditRecipeButton: View {
    @Environment(Recipe.self) private var recipe

    @State private var isPresented = false

    private let action: (() -> Void)?

    init(action: (() -> Void)? = nil) {
        self.action = action
    }

    var body: some View {
        Button {
            if let action {
                action()
            } else {
                isPresented = true
            }
        } label: {
            Label {
                Text("Edit \(recipe.name)")
            } icon: {
                Image(systemName: "pencil")
            }
        }
        .sheet(isPresented: $isPresented) {
            RecipeFormNavigationView(type: .edit)
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    EditRecipeButton()
        .environment(recipes[0])
}
