//
//  RecipeFormNavigationView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import PhotosUI
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
    @State private var ingredients = [IngredientTuple]()
    @State private var steps = [String]()
    @State private var categories = [String]()
    @State private var note = ""

    @State private var photosPickerItems = [PhotosPickerItem]()

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
                Section("Photos") {
                    ScrollView(.horizontal) {
                        LazyHStack {
                            ForEach(photos, id: \.self) { photo in
                                if let image = UIImage(data: photo) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 120)
                                }
                            }
                            PhotosPicker(
                                selection: $photosPickerItems,
                                selectionBehavior: .ordered,
                                matching: .images
                            ) {
                                Image(systemName: "photo.badge.plus")
                            }
                        }
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
                        if name == "Enable Debug" {
                            isDebugOn = true
                        }
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
                                photos: photos,
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
                                photos: photos,
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
                            if let count = try? context.fetchCount(Recipe.descriptor),
                               count.isMultiple(of: 5) {
                                Task {
                                    try await Task.sleep(for: .seconds(2))
                                    requestReview()
                                }
                            }
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
            photos = recipe?.photos ?? []
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
        .onChange(of: photosPickerItems) {
            photos.removeAll()
            Task {
                for item in photosPickerItems {
                    guard let data = try? await item.loadTransferable(type: Data.self) else {
                        continue
                    }

                    var photo = data
                    var compressionQuality = 1.0
                    let maxSize = 500 * 1024

                    while photo.count > maxSize && compressionQuality > 0 {
                        if let jpeg = UIImage(data: data)?.jpegData(compressionQuality: compressionQuality) {
                            photo = jpeg
                        }
                        compressionQuality -= 0.1
                    }

                    photos.append(photo.count < data.count ? photo : data)
                }
            }
        }
        .interactiveDismissDisabled()
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
