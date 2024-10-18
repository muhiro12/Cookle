//
//  AddRecipeButton.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/13.
//

import SwiftUI

struct AddRecipeButton: View {
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Label {
                Text("Add Recipe")
            } icon: {
                Image(systemName: "book.pages")
            }
        }
        .sheet(isPresented: $isPresented) {
            RecipeFormNavigationView(type: .create)
        }
    }
}

#Preview {
    AddRecipeButton()
}
