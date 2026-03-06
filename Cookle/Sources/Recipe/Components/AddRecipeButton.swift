//
//  AddRecipeButton.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/13.
//

import MHPlatform
import SwiftUI

struct AddRecipeButton: View {
    @State private var isPresented = false

    private let action: (() -> Void)?

    var body: some View {
        Button {
            let logger = CookleApp.logger(
                category: "UIAction",
                source: #fileID
            )
            logger.info("add recipe button tapped")
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
                    .accessibilityHidden(true)
            }
        }
        .sheet(isPresented: $isPresented) {
            RecipeFormNavigationView(type: .create)
        }
    }

    init(action: (() -> Void)? = nil) {
        self.action = action
    }
}

#Preview {
    AddRecipeButton()
}
