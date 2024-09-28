//
//  RecipeFormIngredientsSection.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/03.
//

import SwiftUI

typealias RecipeFormIngredient = (ingredient: String, amount: String)

struct RecipeFormIngredientsSection: View {
    @Binding private var ingredients: [RecipeFormIngredient]

    @FocusState private var focusedIndex: Int?

    init(_ ingredients: Binding<[RecipeFormIngredient]>) {
        self._ingredients = ingredients
    }

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
            .onMove {
                ingredients.move(fromOffsets: $0, toOffset: $1)
            }
            .onDelete {
                ingredients.remove(atOffsets: $0)
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
        .onChange(of: ingredients.map { $0.ingredient }) {
            ingredients.removeAll {
                $0.ingredient.isEmpty && $0.amount.isEmpty
            }
            ingredients.append((.empty, .empty))
        }
        .onChange(of: ingredients.map { $0.amount }) {
            ingredients.removeAll {
                $0.ingredient.isEmpty && $0.amount.isEmpty
            }
            ingredients.append((.empty, .empty))
        }
    }
}

#Preview {
    CooklePreview { preview in
        Form { () -> RecipeFormIngredientsSection in
            RecipeFormIngredientsSection(
                .constant(preview.recipes[0].ingredientObjects!.map {
                    ($0.ingredient!.value, $0.amount)
                } + [("", "")])
            )
        }
    }
}
