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

    @State private var name: String
    @State private var imageList: [Data]
    @State private var ingredientList: [String]
    @State private var instructionList: [String]
    @State private var tagList: [String]

    private let recipe: Recipe?

    init(_ recipe: Recipe?) {
        _name = .init(initialValue: recipe?.name ?? "")
        _imageList = .init(initialValue: recipe?.imageList ?? [])
        _ingredientList = .init(initialValue: (recipe?.ingredientList ?? []) + [""])
        _instructionList = .init(initialValue: (recipe?.instructionList ?? []) + [""])
        _tagList = .init(initialValue: (recipe?.tagList ?? []) + [""])

        self.recipe = recipe
    }

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
                Section("Images") {
                    ForEach(imageList, id: \.self) {
                        if let image = UIImage(data: $0) {
                            Image(uiImage: image)
                        }
                    }
                }
                MultiAddableSection(data: $ingredientList,
                                    title: "Ingredients",
                                    tagList: tagStore.tagList.filter { $0.type == .ingredient },
                                    shouldShowNumber: false)
                MultiAddableSection(data: $instructionList,
                                    title: "Instructions",
                                    tagList: tagStore.tagList.filter { $0.type == .instruction },
                                    shouldShowNumber: true)
                MultiAddableSection(data: $tagList,
                                    title: "Tags",
                                    tagList: tagStore.tagList.filter { $0.type == .custom },
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
                                imageList: imageList,
                                ingredientList: ingredientList.filter { !$0.isEmpty },
                                instructionList: instructionList.filter { !$0.isEmpty },
                                tagList: tagList.filter { !$0.isEmpty }
                            )
                            tagStore.insert(with: recipe)
                        } else {
                            let recipe = Recipe(
                                name: name,
                                imageList: imageList,
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
        .interactiveDismissDisabled()
    }
}

#Preview {
    RecipeFormView(PreviewData.randomRecipe())
        .environment(PreviewData.tagStore)
}

#Preview {
    RecipeFormView(nil)
        .environment(PreviewData.tagStore)
}
