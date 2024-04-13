//
//  RecipeFormView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import SwiftUI
import SwiftData

struct RecipeFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.inMemoryContext) private var inMemoryContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var ingredientList = [String]()
    @State private var instructionList = [String]()
    @State private var tagList = [String]()

    @Environment(Recipe.self) private var recipe: Recipe?

    var body: some View {
        NavigationView {
            Form {
                Section("Name") {
                    ZStack(alignment: .trailing) {
                        TextField("Name", text: $name)
                        Text("*")
                            .foregroundStyle(.red)
                    }
                }
                MultiAddableSection(data: $ingredientList,
                                    title: "Ingredients",
                                    tagList: inMemoryContext.ingredientList,
                                    shouldShowNumber: false)
                MultiAddableSection(data: $instructionList,
                                    title: "Instructions",
                                    tagList: inMemoryContext.instructionList,
                                    shouldShowNumber: true)
                MultiAddableSection(data: $tagList,
                                    title: "Tags",
                                    tagList: inMemoryContext.categoryList,
                                    shouldShowNumber: false)
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
                                ingredientList: ingredientList.filter { !$0.isEmpty },
                                instructionList: instructionList.filter { !$0.isEmpty },
                                categoryList: tagList.filter { !$0.isEmpty }
                            )
                            inMemoryContext.insert(with: recipe)
                        } else {
                            let recipe = Recipe(
                                name: name,
                                ingredientList: ingredientList.filter { !$0.isEmpty },
                                instructionList: instructionList.filter { !$0.isEmpty },
                                categoryList: tagList.filter { !$0.isEmpty }
                            )
                            modelContext.insert(recipe)
                            inMemoryContext.insert(with: recipe)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .task {
            name = recipe?.name ?? ""
            ingredientList = (recipe?.ingredientList ?? []) + [""]
            instructionList = (recipe?.instructionList ?? []) + [""]
            tagList = (recipe?.categoryList ?? []) + [""]
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    RecipeFormView()
        .environment(\.inMemoryContext, PreviewData.inMemoryContext)
}


#Preview {
    RecipeFormView()
        .environment(PreviewData.randomRecipe())
        .environment(\.inMemoryContext, PreviewData.inMemoryContext)
}
