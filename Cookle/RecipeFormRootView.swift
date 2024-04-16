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
    @State private var instructions = [String]()
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
                MultiAddableSection<Ingredient>(
                    data: $ingredients,
                    title: "Ingredients",
                    shouldShowNumber: false
                )
                MultiAddableSection<String>(
                    data: $instructions,
                    title: "Instructions",
                    shouldShowNumber: true
                )
                MultiAddableSection<Category>(
                    data: $categories,
                    title: "Tags",
                    shouldShowNumber: false
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
                            recipe.set(
                                name: name,
                                ingredients: ingredients.filter { !$0.isEmpty },
                                instructions: instructions.filter { !$0.isEmpty },
                                categories: categories.filter { !$0.isEmpty }
                            )
                        } else {
                            modelContext.insert(Recipe.factory(
                                name: name,
                                ingredients: ingredients.filter { !$0.isEmpty },
                                instructions: instructions.filter { !$0.isEmpty },
                                categories: categories.filter { !$0.isEmpty }
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
            instructions = recipe?.instructions ?? [""]
            categories = (recipe?.categories.map { $0.value }  ?? []) + [""]
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    RecipeFormRootView()
}


#Preview {
    RecipeFormRootView()
        .environment(PreviewData.randomRecipe())
}
