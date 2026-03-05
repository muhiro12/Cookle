//
//  RecipeFormIngredientsSection.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/03.
//

import SwiftData
import SwiftUI

typealias RecipeFormIngredient = RecipeFormIngredientInput

struct RecipeFormIngredientsSection: View {
    @Binding private var ingredients: [RecipeFormIngredient]

    @FocusState private var focusedIndex: Int?

    var body: some View {
        Section {
            ForEach(ingredients.indices, id: \.self) { index in
                HStack(alignment: .top) {
                    TextField(text: $ingredients[index].ingredient, axis: .vertical) {
                        Text("Spaghetti")
                    }
                    .focused($focusedIndex, equals: index)
                    TextField(text: $ingredients[index].amount) {
                        Text("200g")
                    }
                    .multilineTextAlignment(.trailing)
                }
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        SuggestionButtons<Ingredient>(input: $ingredients[index].ingredient)
                            .hidden(focusedIndex != index)
                    }
                }
            }
            .onMove { sourceOffsets, destinationOffset in
                ingredients.move(fromOffsets: sourceOffsets, toOffset: destinationOffset)
            }
            .onDelete { offsets in
                ingredients.remove(atOffsets: offsets)
            }
        } header: {
            HStack {
                Text("Ingredients")
                Spacer()
                AddMultipleIngredientsButton(ingredients: $ingredients)
                    .font(.caption)
                    .textCase(nil)
            }
        }
        .onChange(of: ingredients.map(\.ingredient)) {
            ingredients.removeAll { ingredient in
                ingredient.ingredient.isEmpty && ingredient.amount.isEmpty
            }
            ingredients.append(.init(ingredient: .empty, amount: .empty))
        }
        .onChange(of: ingredients.map(\.amount)) {
            ingredients.removeAll { ingredient in
                ingredient.ingredient.isEmpty && ingredient.amount.isEmpty
            }
            ingredients.append(.init(ingredient: .empty, amount: .empty))
        }
    }

    init(_ ingredients: Binding<[RecipeFormIngredient]>) {
        self._ingredients = ingredients
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    Form { () -> RecipeFormIngredientsSection in
        let previewIngredients: [RecipeFormIngredient] = recipes[0].ingredientObjects?.compactMap { ingredientObject in
            guard let ingredient = ingredientObject.ingredient else {
                return nil
            }
            return RecipeFormIngredient(
                ingredient: ingredient.value,
                amount: ingredientObject.amount
            )
        } ?? []
        RecipeFormIngredientsSection(
            .constant(
                previewIngredients
                    + [.init(ingredient: .empty, amount: .empty)]
            )
        )
    }
}
