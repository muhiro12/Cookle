//
//  EditRecipeButton.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/13.
//

import SwiftUI

struct EditRecipeButton: View {
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
