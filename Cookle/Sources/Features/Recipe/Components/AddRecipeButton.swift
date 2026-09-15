//
//  AddRecipeButton.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/13.
//

import SwiftUI

struct AddRecipeButton: View {
    @State private var isPresented = false

    @Environment(CookleAppLogging.self)
    private var logging

    private let showsTitle: Bool
    private let action: (() -> Void)?

    var body: some View {
        Button {
            let logger = logging.logger(
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
            if showsTitle {
                Text("Add Recipe")
            } else {
                Label {
                    Text("Add Recipe")
                } icon: {
                    Image(systemName: "plus")
                        .accessibilityHidden(true)
                }
            }
        }
        .sheet(isPresented: $isPresented) {
            RecipeFormNavigationView(type: .create)
        }
    }

    init(showsTitle: Bool = false, action: (() -> Void)? = nil) {
        self.showsTitle = showsTitle
        self.action = action
    }
}

#Preview {
    AddRecipeButton()
        .environment(CookleAppLogging.preview())
}
