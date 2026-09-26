//
//  EditRecipeButton.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/13.
//

import SwiftData
import SwiftUI

struct EditRecipeButton: View {
    @Environment(Recipe.self)
    private var recipe
    @Environment(RecipeFormPresenter.self)
    private var recipeFormPresenter

    var body: some View {
        Button {
            recipeFormPresenter.present(
                .edit,
                recipe: recipe
            )
        } label: {
            Label {
                Text("Edit \(recipe.name)")
            } icon: {
                Image(systemName: "pencil")
                    .accessibilityHidden(true)
            }
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    EditRecipeButton()
        .environment(recipes[0])
}
