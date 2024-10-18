//
//  DuplicateRecipeButton.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 10/18/24.
//

import SwiftUI

struct DuplicateRecipeButton: View {
    @Environment(Recipe.self) private var recipe

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Label {
                Text("Duplicate \(recipe.name)")
            } icon: {
                Image(systemName: "document.on.document")
            }
        }
        .sheet(isPresented: $isPresented) {
            RecipeFormNavigationView()
        }
    }
}

#Preview {
    CooklePreview { preview in
        DuplicateRecipeButton()
            .environment(preview.recipes[.zero])
    }
}
