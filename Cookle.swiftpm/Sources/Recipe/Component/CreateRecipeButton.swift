//
//  CreateRecipeButton.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/21/24.
//

import SwiftUI

struct CreateRecipeButton: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    
    @State private var recipe: Recipe?
    @State private var isConfirmationDialogPresented = false
    @State private var isImagePlaygroundPresented = false

    private let name: String
    private let photos: [Data]
    private let servingSize: String
    private let cookingTime: String
    private let ingredients: [RecipeFormIngredient]
    private let steps: [String]
    private let categories: [String]
    private let note: String

    private let useShortTitle: Bool

    init(name: String,
         photos: [Data],
         servingSize: String,
         cookingTime: String,
         ingredients: [RecipeFormIngredient],
         steps: [String],
         categories: [String],
         note: String,
         useShortTitle: Bool = false) {
        self.name = name
        self.photos = photos
        self.servingSize = servingSize
        self.cookingTime = cookingTime
        self.ingredients = ingredients
        self.steps = steps
        self.categories = categories
        self.note = note
        self.useShortTitle = useShortTitle
    }

    var body: some View {
        Button {
            recipe = Recipe.create(
                context: context,
                name: name,
                photos: zip(photos.indices, photos).map { index, element in
                    .create(context: context, photo: element, order: index + 1)
                },
                servingSize: toInt(servingSize) ?? .zero,
                cookingTime: toInt(cookingTime) ?? .zero,
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
            if recipe?.photos?.isNotEmpty == true {            
                dismiss()
                if Int.random(in: 0..<5) == .zero {
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        requestReview()
                    }
                }
            } else {
                isConfirmationDialogPresented = true    
            }
        } label: {
            Label {
                if useShortTitle {
                    Text("Create")
                } else {
                    Text("Create \(name)")
                }
            } icon: {
                Image(systemName: "book.pages")
            }
        }
        .disabled(
            name.isEmpty
                || (!servingSize.isEmpty && toInt(servingSize) == nil)
                || (!cookingTime.isEmpty && toInt(cookingTime) == nil)
        )
        .confirmationDialog(
            Text("Add a photo?"),
            isPresented: $isConfirmationDialogPresented 
        ) {
            Button("Use Image Playground") {
                isImagePlaygroundPresented = true
            }
            Button("Later", role: .cancel) {}
        } message: {
            Text("No image yet. Try Image Playground?")
        }
        .imagePlaygroundSheet(
            isPresented: $isImagePlaygroundPresented,
            recipe: recipe
        ) { url in
            guard let recipe else {
                return
            }
            recipe.update(
                name: recipe.name, 
                photos: [
                    .create(
                        context: context,
                        photo: url.dataRepresentation.compressed(),
                        order: 1
                    )
                ],
                servingSize: recipe.servingSize,
                cookingTime: recipe.cookingTime,
                ingredients: recipe.ingredientObjects ?? [],
                steps: recipe.steps,
                categories: recipe.categories ?? [],
                note: recipe.note
            )
            dismiss()
        }
    }

    private func toInt(_ string: String) -> Int? {
        Int(string.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? .empty)
    }
}

#Preview {
    CreateRecipeButton(
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
