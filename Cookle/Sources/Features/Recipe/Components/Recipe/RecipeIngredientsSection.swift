//
//  RecipeIngredientsSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftData
import SwiftUI

struct RecipeIngredientsSection: View {
    @Environment(Recipe.self)
    private var recipe
    @Environment(\.openCookleRoute)
    private var openCookleRoute

    var body: some View {
        if let objects = recipe.ingredientObjects,
           !objects.isEmpty {
            Section {
                ForEach(objects.sorted()) { object in
                    ingredientRow(for: object)
                }
            } header: {
                Text("Ingredients")
            }
        }
    }
}

private extension RecipeIngredientsSection {
    @ViewBuilder
    func ingredientRow(for object: IngredientObject) -> some View {
        if let ingredient = object.ingredient {
            Button {
                openIngredient(ingredient)
            } label: {
                ingredientLabel(
                    name: ingredient.value,
                    amount: object.amount
                )
                .cookleButtonRowContent()
            }
            .buttonStyle(.plain)
        } else {
            ingredientLabel(
                name: "",
                amount: object.amount
            )
        }
    }

    func ingredientLabel(
        name: String,
        amount: String
    ) -> some View {
        HStack {
            Text(name)
            Spacer()
            Text(amount)
                .foregroundStyle(.secondary)
        }
    }

    func openIngredient(_ ingredient: Ingredient) {
        openCookleRoute(
            .tagDetail(
                kind: .ingredient,
                id: PersistentModelStableIdentifierCodec.stableIdentifier(
                    for: ingredient
                )
            )
        )
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    List {
        RecipeIngredientsSection()
            .environment(recipes[0])
    }
}
