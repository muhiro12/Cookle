//
//  RecipeFormNavigationView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import StoreKit
import SwiftData
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
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if let recipe {
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
                        } else {
                            _ = Recipe.create(
                                context: context,
                                name: name,
                                photos: zip(photos.indices, photos).map { index, element in
                                    .create(context: context, photo: element, order: index + 1)
                                },
                                servingSize: .init(servingSize) ?? .zero,
                                cookingTime: .init(cookingTime) ?? .zero,
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
                        }
                        dismiss()
                        if Int.random(in: 0..<5) == .zero {
                            Task {
                                try? await Task.sleep(for: .seconds(2))
                                requestReview()
                            }
                        }
                    } label: {
                        Text(recipe != nil ? "Update" : "Add")
                    }
                    .disabled(
                        name.isEmpty
                            || (!servingSize.isEmpty && Int(servingSize) == nil)
                            || (!cookingTime.isEmpty && Int(cookingTime) == nil)
                    )
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
