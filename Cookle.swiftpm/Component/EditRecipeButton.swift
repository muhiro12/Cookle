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
        Button("Edit Recipe", systemImage: "pencil") {
            isPresented = true
        }
        .sheet(isPresented: $isPresented) {
            RecipeFormRootView()
        }
    }
}

#Preview {
    ModelContainerPreview { preview in
        EditRecipeButton()
            .environment(preview.recipes[0])
    }
}
