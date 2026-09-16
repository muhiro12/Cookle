//
//  AddRecipeButton.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/13.
//

import SwiftUI

struct AddRecipeButton: View {
    private struct Presentation: Identifiable {
        let id = UUID()
        let source: RecipeImportSource?
    }

    @State private var presentation: Presentation?

    @Environment(CookleAppLogging.self)
    private var logging

    private let showsTitle: Bool
    private let action: (() -> Void)?

    var body: some View {
        Group {
            if #available(iOS 26.0, *), action == nil {
                Menu {
                    Button("Enter Manually", systemImage: "pencil") {
                        beginRegistration()
                    }
                    ForEach(RecipeImportSource.allCases) { source in
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
        .sheet(item: $presentation) { presentation in
            RecipeFormNavigationView(type: .create, initialImportSource: presentation.source)
        }
    }

    @ViewBuilder private var buttonLabel: some View {
        if showsTitle {
            Text("Add Recipe")
        } else {
            Label("Add Recipe", systemImage: "plus")
        }
    }

    init(showsTitle: Bool = false, action: (() -> Void)? = nil) {
        self.showsTitle = showsTitle
        self.action = action
    }
}

private extension AddRecipeButton {
    func beginRegistration(source: RecipeImportSource? = nil) {
        let logger = logging.logger(category: "UIAction", source: #fileID)
        logger.info("add recipe button tapped")
        if let action {
            action()
        } else {
            presentation = .init(source: source)
        }
    }
}

#Preview {
    AddRecipeButton()
        .environment(CookleAppLogging.preview())
}
