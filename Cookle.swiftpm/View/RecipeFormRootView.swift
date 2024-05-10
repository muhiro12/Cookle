//
//  RecipeFormRootView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import SwiftUI
import SwiftData

struct RecipeFormRootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var servingSize = ""
    @State private var cookingTime = ""
    @State private var ingredients = [IngredientTuple]()
    @State private var steps = [String]()
    @State private var categories = [String]()

    @Environment(Recipe.self) private var recipe: Recipe?

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    ZStack(alignment: .trailing) {
                        TextField("Name", text: $name)
                        Text("*")
                            .foregroundStyle(.red)
                    }
                }
                Section("Serving Size") {
                    TextField("Serving Size", text: $servingSize)
                        .keyboardType(.numberPad)
                }
                Section("Cooking Time") {
                    TextField("Cooking Time", text: $cookingTime)
                        .keyboardType(.numberPad)
                }
                MultiAddableIngredientSection(data: $ingredients)
                MultiAddableStepSection(data: $steps)
                MultiAddableCategorySection(data: $categories)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem {
                    EditButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(recipe != nil ? "Update" : "Add") {
                        if let recipe {
                            recipe.update(
                                context: context,
                                name: name,
                                servingSize: Int(servingSize) ?? .zero,
                                cookingTime: Int(cookingTime) ?? .zero,
                                ingredients: ingredients.compactMap {
                                    guard !$0.ingredient.isEmpty else {
                                        return nil
                                    }
                                    return .create(context: context, ingredient: $0.ingredient, amount: $0.amount)
                                },
                                steps: steps.filter { !$0.isEmpty },
                                categories: categories.compactMap {
                                    guard !$0.isEmpty else {
                                        return nil
                                    }
                                    return .create(context: context, value: $0)
                                }
                            )
                        } else {
                            _ = Recipe.create(
                                context: context,
                                name: name,
                                servingSize: Int(servingSize) ?? .zero,
                                cookingTime: Int(cookingTime) ?? .zero,
                                ingredients: ingredients.compactMap {
                                    guard !$0.ingredient.isEmpty else {
                                        return nil
                                    }
                                    return .create(context: context, ingredient: $0.ingredient, amount: $0.amount)
                                },
                                steps: steps.filter { !$0.isEmpty },
                                categories: categories.compactMap {
                                    guard !$0.isEmpty else {
                                        return nil
                                    }
                                    return .create(context: context, value: $0)
                                }
                            )
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty || Int(servingSize) == nil || Int(cookingTime) == nil)
                }
            }
        }
        .task {
            name = recipe?.name ?? ""
            servingSize = recipe?.servingSize.description ?? ""
            cookingTime = recipe?.cookingTime.description ?? ""
            ingredients = (recipe?.ingredientObjects.map { ($0.ingredient.value, $0.amount) } ?? []) + [("", "")]
            steps = recipe?.steps ?? [""]
            categories = (recipe?.categories.map { $0.value }  ?? []) + [""]
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    RecipeFormRootView()
}


#Preview {
    ModelContainerPreview { preview in
        RecipeFormRootView()
            .environment(preview.recipes[0])
    }
}
