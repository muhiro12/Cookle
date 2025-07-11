//
//  RecipeFormView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import StoreKit
import SwiftUI

struct RecipeFormView: View {
    @Environment(\.dismiss) private var dismiss

    @Environment(Recipe.self) private var recipe: Recipe?
    @Environment(\.modelContext) private var context

    @AppStorage(.isDebugOn) private var isDebugOn

    @State private var name = ""
    @State private var photos = [PhotoData]()
    @State private var servingSize = ""
    @State private var cookingTime = ""
    @State private var ingredients = [RecipeFormIngredient]()
    @State private var steps = [String]()
    @State private var categories = [String]()
    @State private var note = ""

    @State private var editMode = EditMode.inactive
    @State private var isDebugAlertPresented = false

    private let type: RecipeFormType

    init(type: RecipeFormType) {
        self.type = type
    }

    var body: some View {
        Form {
            RecipeFormNameSection($name)
                .hidden(editMode == .active)
            RecipeFormPhotosSection($photos)
            if #available(iOS 26.0, *) {
                RecipeFormInferSection(
                    name: $name,
                    servingSize: $servingSize,
                    cookingTime: $cookingTime,
                    ingredients: $ingredients,
                    steps: $steps,
                    categories: $categories,
                    note: $note
                )
            }
            RecipeFormServingSizeSection($servingSize)
                .hidden(editMode == .active)
            RecipeFormCookingTimeSection($cookingTime)
                .hidden(editMode == .active)
            RecipeFormIngredientsSection($ingredients)
            RecipeFormStepsSection($steps)
            RecipeFormCategoriesSection($categories)
            RecipeFormNoteSection($note)
                .hidden(editMode == .active)
            Section {
                Button {
                    withAnimation {
                        editMode = editMode.isEditing ? .inactive : .active
                    }
                } label: {
                    editMode == .inactive ? Text("Change Order or Delete Row") : Text("Done Edit")
                }
                .frame(maxWidth: .infinity)
            }
        }
        .environment(\.editMode, $editMode)
        .navigationTitle(editMode == .inactive ? Text("Recipe") : Text("Editing..."))
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
            switch editMode {
            case .active:
                ToolbarItem {
                    Button {
                        withAnimation {
                            editMode = .inactive
                        }
                    } label: {
                        Text("Done")
                    }
                }
            default:
                switch type {
                case .create,
                     .duplicate:
                    ToolbarItem(placement: .confirmationAction) {
                        CreateRecipeButton(
                            name: name,
                            photos: photos,
                            servingSize: servingSize,
                            cookingTime: cookingTime,
                            ingredients: ingredients,
                            steps: steps,
                            categories: categories,
                            note: note,
                            useShortTitle: true
                        )
                        .labelStyle(.titleOnly)
                    }
                case .edit:
                    ToolbarItem(placement: .confirmationAction) {
                        UpdateRecipeButton(
                            name: name,
                            photos: photos,
                            servingSize: servingSize,
                            cookingTime: cookingTime,
                            ingredients: ingredients,
                            steps: steps,
                            categories: categories,
                            note: note,
                            useShortTitle: true
                        )
                        .labelStyle(.titleOnly)
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .confirmationDialog(
            Text("Debug"),
            isPresented: $isDebugAlertPresented
        ) {
            Button {
                isDebugOn = true
                dismiss()
            } label: {
                Text("OK")
            }
            Button(role: .cancel) {
            } label: {
                Text("Cancel")
            }
        } message: {
            Text("Are you really going to use DebugMode?")
        }
        .task {
            guard let model = recipe else {
                return
            }
            name = model.name
            photos = model.photoObjects?.sorted().compactMap {
                guard let photo = $0.photo else {
                    return nil
                }
                return .init(data: photo.data, source: photo.source)
            } ?? .empty
            servingSize = model.servingSize.description
            cookingTime = model.cookingTime.description
            ingredients = (model.ingredientObjects?.sorted().compactMap { object in
                guard let ingredient = object.ingredient else {
                    return nil
                }
                return (ingredient.value, object.amount)
            } ?? .empty) + [(.empty, .empty)]
            steps = (model.steps) + [.empty]
            categories = (model.categories?.map(\.value) ?? .empty) + [.empty]
            note = model.note
        }
    }
}

#Preview {
    RecipeFormNavigationView(type: .create)
}

#Preview {
    CooklePreview { preview in
        RecipeFormNavigationView(type: .edit)
            .environment(preview.recipes[0])
    }
}
