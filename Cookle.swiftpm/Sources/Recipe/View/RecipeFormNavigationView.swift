//
//  RecipeFormNavigationView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import StoreKit
import SwiftUI

struct RecipeFormNavigationView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    @Environment(Recipe.self) private var recipe: Recipe?

    @AppStorage(.isDebugOn) private var isDebugOn

    @State private var name = ""
    @State private var photos = [Data]()
    @State private var servingSize = ""
    @State private var cookingTime = ""
    @State private var ingredients = [RecipeFormIngredient]()
    @State private var steps = [String]()
    @State private var categories = [String]()
    @State private var note = ""

    @State private var isDebugAlertPresented = false

    var body: some View {
        NavigationStack {
            Form {
                RecipeFormNameSection($name)
                RecipeFormPhotosSection($photos)
                RecipeFormServingSizeSection($servingSize)
                RecipeFormCookingTimeSection($cookingTime)
                RecipeFormIngredientsSection($ingredients)
                RecipeFormStepsSection($steps)
                RecipeFormCategoriesSection($categories)
                RecipeFormNoteSection($note)
            }
            .navigationTitle(Text("Recipe"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if name == "Enable Debug" {
                            name = .empty
                            isDebugAlertPresented = true
                            return
                        }
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                ToolbarItem {
                    EditButton()
                }
                if let recipe {
                    ToolbarItem(placement: .confirmationAction) {
                        CreateRecipeButton(
                            name: name,
                            photos: photos,
                            servingSize: servingSize,
                            cookingTime: cookingTime,
                            ingredients: ingredients,
                            steps: steps,
                            categories: categories,
                            note: note
                        )
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        UpdateRecipeButton(
                            name: name,
                            photos: photos,
                            servingSize: servingSize,
                            cookingTime: cookingTime,
                            ingredients: ingredients,
                            steps: steps,
                            categories: categories,
                            note: note
                        )
                        .environment(recipe)
                    }
                } else {
                    ToolbarItem(placement: .confirmationAction) {
                        CreateRecipeButton(
                            name: name,
                            photos: photos,
                            servingSize: servingSize,
                            cookingTime: cookingTime,
                            ingredients: ingredients,
                            steps: steps,
                            categories: categories,
                            note: note
                        )
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .alert("Debug", isPresented: $isDebugAlertPresented) {
            Button(role: .cancel) {
            } label: {
                Text("Cancel")
            }
            Button {
                isDebugOn = true
                dismiss()
            } label: {
                Text("OK")
            }
        } message: {
            Text("Are you really going to use DebugMode?")
        }
        .task {
            name = recipe?.name ?? ""
            photos = recipe?.photos.orEmpty.map { $0.data } ?? []
            servingSize = recipe?.servingSize.description ?? ""
            cookingTime = recipe?.cookingTime.description ?? ""
            ingredients = (recipe?.ingredientObjects.orEmpty.sorted { $0.order < $1.order }.compactMap { object in
                guard let ingredient = object.ingredient else {
                    return nil
                }
                return (ingredient.value, object.amount)
            } ?? []) + [("", "")]
            steps = (recipe?.steps ?? []) + [""]
            categories = (recipe?.categories.orEmpty.map { $0.value } ?? []) + [""]
            note = recipe?.note ?? ""
        }
    }
}

#Preview {
    RecipeFormNavigationView()
}

#Preview {
    CooklePreview { preview in
        RecipeFormNavigationView()
            .environment(preview.recipes[0])
    }
}
