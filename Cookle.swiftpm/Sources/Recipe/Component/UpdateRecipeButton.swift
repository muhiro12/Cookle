//
//  UpdateRecipeButton.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/21/24.
//

import SwiftUI

struct UpdateRecipeButton: View {
    @Environment(Recipe.self) private var recipe: Recipe
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    private let name: String
    private let photos: [Data]
    private let servingSize: String
    private let cookingTime: String
    private let ingredients: [RecipeFormIngredient]
    private let steps: [String]
    private let categories: [String]
    private let note: String

    init(name: String,
         photos: [Data],
         servingSize: String,
         cookingTime: String,
         ingredients: [RecipeFormIngredient],
         steps: [String],
         categories: [String],
         note: String) {
        self.name = name
        self.photos = photos
        self.servingSize = servingSize
        self.cookingTime = cookingTime
        self.ingredients = ingredients
        self.steps = steps
        self.categories = categories
        self.note = note
    }

    var body: some View {
        Button {
            recipe.update(
                name: name,
                photos: zip(photos.indices, photos).map { index, element in
                    .create(context: context, photo: element, order: index + 1)
                },
                servingSize: Int(servingSize) ?? .zero,
                cookingTime: Int(cookingTime) ?? .zero,
                ingredients: zip(ingredients.indices, ingredients).compactMap { index, element in
                    guard !element.ingredient.isEmpty else {
                        return nil
                    }
                    return .create(context: context, ingredient: element.ingredient, amount: element.amount, order: index + 1)
                },
                steps: steps.filter { !$0.isEmpty },
                categories: categories.compactMap {
                    guard !$0.isEmpty else {
                        return nil
                    }
                    return .create(context: context, value: $0)
                },
                note: note
            )
            dismiss()
            if Int.random(in: 0..<5) == .zero {
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    requestReview()
                }
            }
        } label: {
            Text("Update")
        }
        .disabled(
            name.isEmpty
                || (!servingSize.isEmpty && Int(servingSize) == nil)
                || (!cookingTime.isEmpty && Int(cookingTime) == nil)
        )
    }
}

#Preview {
    UpdateRecipeButton(
        name: .empty,
        photos: .empty,
        servingSize: .empty,
        cookingTime: .empty,
        ingredients: .empty,
        steps: .empty,
        categories: .empty,
        note: .empty
    )
}
