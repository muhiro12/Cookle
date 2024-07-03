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
                    TextField(text: $name) {
                        Text("Name")
                    }
                } header: {
                    HStack {
                        Text("Name")
                        Text("*")
                            .foregroundStyle(.red)
                    }
                }
                Section {
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
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                } header: {
                    Text("Photos")
                }
                Section {
                    HStack {
                        TextField(text: $servingSize) {
                            Text("Serving Size")
                        }
                        .keyboardType(.numberPad)
                        Text("servings")
                    }
                } header: {
                    Text("Serving Size")
                }
                Section {
                    HStack {
                        TextField(text: $cookingTime) {
                            Text("Cooking Time")
                        }
                        .keyboardType(.numberPad)
                        Text("minutes")
                    }
                } header: {
                    Text("Cooking Time")
                }
                MultiAddableIngredientSection(data: $ingredients)
                MultiAddableStepSection(data: $steps)
                MultiAddableCategorySection(data: $categories)
                Section {
                    TextField(text: $note, axis: .vertical) {
                        Text("Note")
                    }
                } header: {
                    Text("Note")
                }
            }
            .navigationTitle(Text("Recipe"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if name == "Enable Debug" {
                            isDebugOn = true
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
                            if let count = try? context.fetchCount(Recipe.descriptor),
                               count.isMultiple(of: 5) {
                                Task {
                                    try await Task.sleep(for: .seconds(2))
                                    requestReview()
                                }
                            }
                        }
                        dismiss()
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
        .onChange(of: photosPickerItems) {
            photos = (recipe?.photos).orEmpty.map { $0.data }
            Task {
                for item in photosPickerItems {
                    guard let data = try? await item.loadTransferable(type: Data.self) else {
                        continue
                    }

                    var photo = data
                    var compressionQuality = 1.0
                    let maxSize = 500 * 1_024

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
