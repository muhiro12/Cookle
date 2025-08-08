//
//  AddRecipeButton.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/13.
//

import SwiftUI

struct AddRecipeButton: View {
    @State private var isPresented = false

    private let action: (() -> Void)?

    init(action: (() -> Void)? = nil) {
        self.action = action
    }

    var body: some View {
        Button {
            Logger(#file).info("AddRecipeButton tapped")
            if let action {
                action()
            } else {
                isPresented = true
            }
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
