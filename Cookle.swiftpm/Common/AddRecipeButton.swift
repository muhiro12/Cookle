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
        Button("Add Recipe", systemImage: "plus") {
            isPresented = true
        }
        .sheet(isPresented: $isPresented) {
            RecipeFormNavigationView()
        }
    }
}

#Preview {
    AddRecipeButton()
}
