//
//  RecipeFormRootView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import SwiftUI
import SwiftData

struct RecipeFormRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var ingredients = [String]()
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
                MultiAddableSection<Category>(
                    data: $categories,
                    title: "Categories",
                    shouldShowNumber: false
                )
                Section("Serving Size") {
                    Text("TODO:" + " servings") // TODO: Build servingSize TextField
                }
                Section("Cooking Time") {
                    Text("TODO:" + " minutes") // TODO: Build cookingTime TextField
                }
                MultiAddableSection<Ingredient>(
                    data: $ingredients,
                    title: "Ingredients",
                    shouldShowNumber: false
                )
                MultiAddableSection<String>(
                    data: $steps,
                    title: "Steps",
                    shouldShowNumber: true
                )
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
                                context: modelContext,
                                name: name,
                                categories: categories.filter { !$0.isEmpty },
                                servingSize: 0, // TODO: Set servingSize
                                cookingTime: 0, // TODO: Set cookingTime
                                ingredients: ingredients.filter { !$0.isEmpty },
                                steps: steps.filter { !$0.isEmpty }
                            )
                        } else {
                            modelContext.insert(Recipe.create(
                                context: modelContext,
                                name: name,
                                categories: categories.filter { !$0.isEmpty },
                                servingSize: 0, // TODO: Set servingSize
                                cookingTime: 0, // TODO: Set cookingTime
                                ingredients: ingredients.filter { !$0.isEmpty },
                                steps: steps.filter { !$0.isEmpty }
                            ))
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .task {
            name = recipe?.name ?? ""
            ingredients = (recipe?.ingredients.map { $0.value } ?? []) + [""]
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
