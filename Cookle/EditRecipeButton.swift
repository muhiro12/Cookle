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
            RecipeFormView()
        }
    }
}

#Preview {
    EditRecipeButton()
        .environment(PreviewData.randomRecipe())
        .environment(PreviewData.tagStore)
}
