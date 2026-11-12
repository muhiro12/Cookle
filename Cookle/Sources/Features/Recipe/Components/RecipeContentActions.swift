import SwiftUI
import UIKit

/// Native text transfer, separate from sharing a reference to this recipe.
struct RecipeContentActions: View {
    @Environment(Recipe.self)
    private var recipe

    var body: some View {
        Button {
            UIPasteboard.general.string = contentText
        } label: {
            Label("Copy Recipe Content", systemImage: "doc.on.doc")
        }
        ShareLink(item: contentText) {
            Label("Share Recipe Content", systemImage: "square.and.arrow.up")
        }
    }

    private var contentText: String {
        RecipeOperations.contentText(
            for: recipe,
            labels: .init(
                servings: String(localized: "Serving Size"),
                cookingTime: String(localized: "Cooking Time (minutes)"),
                ingredients: String(localized: "Ingredients"),
                steps: String(localized: "Steps"),
                categories: String(localized: "Categories"),
                note: String(localized: "Note")
            )
        )
    }
}
