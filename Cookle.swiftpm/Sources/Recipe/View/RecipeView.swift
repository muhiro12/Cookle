//
//  RecipeView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import SwiftData
import SwiftUI

struct RecipeView: View {
    @Environment(Recipe.self) private var recipe

    @State private var isPhotoDetailPresented = false

    var body: some View {
        List {
            if let photoObjects = recipe.photoObjects,
               photoObjects.isNotEmpty {
                Section("Photos") {
                    ScrollView(.horizontal) {
                        LazyHStack {
                            ForEach(photoObjects.sorted { $0.order < $1.order }, id: \.self) { photoObject in
                                if let photo = photoObject.photo,
                                   let image = UIImage(data: photo.data) {
                                    Button {
                                        isPhotoDetailPresented = true
                                    } label: {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 240)
                                            .clipShape(.rect(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .listRowInsets(.init(.zero))
                    .listRowBackground(Color.clear)
                }
            }
            if recipe.servingSize.isNotZero {
                Section("Serving Size") {
                    Text(recipe.servingSize.description + " servings")
                }
            }
            if recipe.cookingTime.isNotZero {
                Section("Cooking Time") {
                    Text(recipe.cookingTime.description + " minutes")
                }
            }
            if let ingredientObjects = recipe.ingredientObjects,
               ingredientObjects.isNotEmpty {
                Section("Ingredients") {
                    ForEach(ingredientObjects.sorted { $0.order < $1.order }, id: \.self) { ingredientObject in
                        HStack {
                            Text(ingredientObject.ingredient?.value ?? "")
                            Spacer()
                            Text(ingredientObject.amount)
                        }
                    }
                }
            }
            if recipe.steps.isNotEmpty {
                Section("Steps") {
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { values in
                        HStack(alignment: .top) {
                            Text((values.offset + 1).description + ".")
                                .frame(width: 24)
                            Text(values.element)
                        }
                    }
                }
            }
            Section {
                Advertisement(.medium)
            }
            if let categories = recipe.categories,
               categories.isNotEmpty {
                Section("Categories") {
                    ForEach(categories, id: \.self) {
                        Text($0.value)
                    }
                }
            }
            if recipe.note.isNotEmpty {
                Section("Note") {
                    Text(recipe.note)
                }
            }
            if let diaries = recipe.diaries,
               diaries.isNotEmpty {
                Section("Diaries") {
                    ForEach(diaries) {
                        Text($0.date.formatted(.dateTime.year().month().day()))
                    }
                }
            }
            Section("Created At") {
                Text(recipe.createdTimestamp.formatted(.dateTime.year().month().day()))
            }
            Section("Updated At") {
                Text(recipe.modifiedTimestamp.formatted(.dateTime.year().month().day()))
            }
        }
        .fullScreenCover(isPresented: $isPhotoDetailPresented) {
            PhotoDetailView(photos: recipe.photos.orEmpty)
        }
        .task {
            UIApplication.shared.isIdleTimerDisabled = true
            try? await Task.sleep(for: .seconds(60 * 10))
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

#Preview {
    CooklePreview { preview in
        RecipeView()
            .environment(preview.recipes[0])
    }
}
