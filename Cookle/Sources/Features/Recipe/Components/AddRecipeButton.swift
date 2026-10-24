//
//  AddRecipeButton.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/13.
//

import SwiftUI

struct AddRecipeButton: View {
    @Environment(CookleAppLogging.self)
    private var logging
    @Environment(RecipeFormPresenter.self)
    private var recipeFormPresenter

    private let action: (() -> Void)?

    var body: some View {
        Group {
            if #available(iOS 26.0, *), action == nil {
                Menu {
                    Button("Enter Manually", systemImage: "pencil") {
                        beginRegistration()
                    }
                    ForEach(RecipeDraftSource.allCases.filter(\.isAvailable)) { source in
                        Button {
                            beginRegistration(source: source)
                        } label: {
                            Label(source.title, systemImage: source.systemImage)
                        }
                    }
                } label: {
                    buttonLabel
                }
            } else {
                Button {
                    beginRegistration()
                } label: {
                    buttonLabel
                }
            }
        }
    }

    private var buttonLabel: some View {
        Label("Add Recipe", systemImage: "book.badge.plus")
    }

    init(action: (() -> Void)? = nil) {
        self.action = action
    }
}

private extension AddRecipeButton {
    func beginRegistration(source: RecipeDraftSource? = nil) {
        let logger = logging.logger(category: "UIAction", source: #fileID)
        logger.info("add recipe button tapped")
        if let action {
            action()
        } else {
            recipeFormPresenter.present(
                .create,
                draftSource: source
            )
        }
    }
}

#Preview {
    AddRecipeButton()
        .environment(CookleAppLogging.preview())
        .recipeFormPresentationHost()
}
