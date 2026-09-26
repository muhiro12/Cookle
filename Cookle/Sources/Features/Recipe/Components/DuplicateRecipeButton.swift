//
//  DuplicateRecipeButton.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 10/18/24.
//

import SwiftData
import SwiftUI

struct DuplicateRecipeButton: View {
    @Environment(Recipe.self)
    private var recipe
    @Environment(RecipeFormPresenter.self)
    private var recipeFormPresenter

    private let showsRecipeName: Bool

    var body: some View {
        Button {
            recipeFormPresenter.present(
                .duplicate,
                recipe: recipe
            )
        } label: {
            Label {
                if showsRecipeName {
                    Text("Duplicate \(recipe.name)")
                } else {
                    Text("Duplicate")
                }
            } icon: {
                Image(systemName: "document.on.document")
                    .accessibilityHidden(true)
            }
        }
    }

    init(showsRecipeName: Bool = true) {
        self.showsRecipeName = showsRecipeName
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    DuplicateRecipeButton()
        .environment(recipes[.zero])
}
