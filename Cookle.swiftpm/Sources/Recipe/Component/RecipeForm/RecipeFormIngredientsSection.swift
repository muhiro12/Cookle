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

    init(_ ingredients: Binding<[RecipeFormIngredient]>) {
        self._ingredients = ingredients
    }

    var body: some View {
        Section {
            ForEach(ingredients.indices, id: \.self) { index in
                HStack(alignment: .top) {
                    TextField(
                        text: .init(
                            get: {
                                guard index < ingredients.endIndex else {
                                    return ""
                                }
                                return ingredients[index].ingredient
                            },
                            set: { value in
                                guard index < ingredients.endIndex else {
                                    return
                                }
                                ingredients[index].ingredient = value
                                guard !value.isEmpty,
                                      !ingredients.contains(where: { $0.ingredient.isEmpty }) else {
                                    return
                                }
                                ingredients.append(("", ""))
                            }
                        ),
                        axis: .vertical
                    ) {
                        Text("Ingredient")
                    }
                    TextField(text: $ingredients[index].amount) {
                        Text("Amount")
                    }
                    .multilineTextAlignment(.trailing)
                    SuggestionMenu<Ingredient>(input: $ingredients[index].ingredient)
                        .frame(width: 24)
                }
            }
            .onMove {
                ingredients.move(fromOffsets: $0, toOffset: $1)
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
        .environment(\.editMode, .constant(.active))
    }
}
