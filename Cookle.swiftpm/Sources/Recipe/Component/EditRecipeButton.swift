//
//  EditRecipeButton.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/13.
//

import SwiftUI

struct EditRecipeButton: View {
    @Environment(Recipe.self) private var recipe

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
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

#Preview {
    CooklePreview { preview in
        EditRecipeButton()
            .environment(preview.recipes[0])
    }
}
