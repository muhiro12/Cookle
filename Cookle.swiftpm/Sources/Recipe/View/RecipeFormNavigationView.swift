//
//  RecipeFormNavigationView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import SwiftUI
import SwiftData

struct RecipeFormNavigationView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Environment(Recipe.self) private var recipe: Recipe?

    @State private var name = ""
    @State private var servingSize = ""
    @State private var cookingTime = ""
    @State private var ingredients = [IngredientTuple]()
    @State private var steps = [String]()
    @State private var categories = [String]()
    @State private var note = ""

    @State private var isPresented = false
    @State private var text = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                } header: {
                    HStack {
                        Text("Name")
                        Text("*")
                            .foregroundStyle(.red)
                    }
                }
                Section("Serving Size") {
                    HStack {
                        TextField("Serving Size", text: $servingSize)
                            .keyboardType(.numberPad)
                        Text("servings")
                    }
                }
                Section("Cooking Time") {
                    HStack {
                        TextField("Cooking Time", text: $cookingTime)
                            .keyboardType(.numberPad)
                        Text("minutes")
                    }
                }
                MultiAddableIngredientSection(data: $ingredients)
                MultiAddableStepSection(data: $steps)
                MultiAddableCategorySection(data: $categories)
                Section("Note") {
                    TextField("Note", text: $note, axis: .vertical)
                }
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
                                },
                                note: note
                            )
                        } else {
                            _ = Recipe.create(
                                context: context,
                                name: name,
                                servingSize: .init(servingSize) ?? .zero,
                                cookingTime: .init(cookingTime) ?? .zero,
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
                                },
                                note: note
                            )
                        }
                        dismiss()
                    }
                    .disabled(
                        name.isEmpty
                            || (!servingSize.isEmpty && Int(servingSize) == nil)
                            || (!cookingTime.isEmpty && Int(cookingTime) == nil)
                    )
                }
            }
        }
        .task {
            name = recipe?.name ?? ""
            servingSize = recipe?.servingSize.description ?? ""
            cookingTime = recipe?.cookingTime.description ?? ""
            ingredients = (recipe?.ingredientObjects.map { ($0.ingredient.value, $0.amount) } ?? []) + [("", "")]
            steps = (recipe?.steps ?? []) + [""]
            categories = (recipe?.categories.map { $0.value }  ?? []) + [""]
            note = recipe?.note ?? ""
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    RecipeFormNavigationView()
}

#Preview {
    ModelContainerPreview { preview in
        RecipeFormNavigationView()
            .environment(preview.recipes[0])
    }
}
