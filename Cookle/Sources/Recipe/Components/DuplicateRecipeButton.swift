//
//  DuplicateRecipeButton.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 10/18/24.
//

import SwiftUI

struct DuplicateRecipeButton: View {
    @Environment(RecipeEntity.self) private var recipe

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
                Text("Duplicate \(recipe.name)")
            } icon: {
                Image(systemName: "document.on.document")
            }
        }
        .sheet(isPresented: $isPresented) {
            RecipeFormNavigationView(type: .duplicate)
        }
    }
}

#Preview {
    CooklePreview { preview in
        DuplicateRecipeButton()
            .environment(preview.recipes[.zero])
    }
}
