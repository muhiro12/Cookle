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
    @Environment(\.dismiss) private var dismiss

    @Environment(TagStore.self) private var tagStore

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
                                    tagList: tagStore.ingredientTagList,
                                    shouldShowNumber: false)
                MultiAddableSection(data: $instructionList,
                                    title: "Instructions",
                                    tagList: tagStore.instructionTagList,
                                    shouldShowNumber: true)
                MultiAddableSection(data: $tagList,
                                    title: "Tags",
                                    tagList: tagStore.customTagList,
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
                                tagList: tagList.filter { !$0.isEmpty }
                            )
                            tagStore.insert(with: recipe)
                        } else {
                            let recipe = Recipe(
                                name: name,
                                ingredientList: ingredientList.filter { !$0.isEmpty },
                                instructionList: instructionList.filter { !$0.isEmpty },
                                tagList: tagList.filter { !$0.isEmpty }
                            )
                            modelContext.insert(recipe)
                            tagStore.insert(with: recipe)
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
            tagList = (recipe?.tagList ?? []) + [""]
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    RecipeFormView()
        .environment(PreviewData.tagStore)
}


#Preview {
    RecipeFormView()
        .environment(PreviewData.randomRecipe())
        .environment(PreviewData.tagStore)
}
