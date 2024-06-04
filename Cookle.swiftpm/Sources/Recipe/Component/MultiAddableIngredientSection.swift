//
//  MultiAddableIngredientSection.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/03.
//

import SwiftUI

typealias IngredientTuple = (ingredient: String, amount: String)

struct MultiAddableIngredientSection: View {
    @Binding private var data: [IngredientTuple]

    init(data: Binding<[IngredientTuple]>) {
        self._data = data
    }

    var body: some View {
        Section {
            ForEach(data.indices, id: \.self) { index in
                HStack(alignment: .top) {
                    TextField(
                        "Ingredient",
                        text: .init(
                            get: {
                                guard index < data.endIndex else {
                                    return ""
                                }
                                return data[index].ingredient
                            },
                            set: { value in
                                guard index < data.endIndex else {
                                    return
                                }
                                data[index].ingredient = value
                                guard !value.isEmpty,
                                      !data.contains(where: { $0.ingredient.isEmpty }) else {
                                    return
                                }
                                data.append(("", ""))
                            }
                        ),
                        axis: .vertical
                    )
                    TextField("Amount", text: $data[index].amount)
                        .multilineTextAlignment(.trailing)
                    SuggestionMenu<Ingredient>(input: $data[index].ingredient)
                        .frame(width: 24)
                }
            }
            .onDelete {
                data.remove(atOffsets: $0)
                guard data.isEmpty else {
                    return
                }
                data.append(("", ""))
            }
        } header: {
            HStack {
                Text("Ingredients")
                Spacer()
                AddMultipleIngredientsButton(ingredients: $data)
                    .font(.caption)
            }
        }
    }
}

#Preview {
    CooklePreview { preview in
        Form { () -> MultiAddableIngredientSection in
            MultiAddableIngredientSection(
                data: .constant(preview.recipes[0].ingredientObjects.map {
                    ($0.ingredient.value, $0.amount)
                } + [("", "")])
            )
        }
    }
}
