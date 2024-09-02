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

    @AppStorage(.isSubscribeOn) private var isSubscribeOn

    @State private var isPhotoDetailPresented = false

    var body: some View {
        List {
            if let photoObjects = recipe.photoObjects,
               photoObjects.isNotEmpty {
                Section {
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
                } header: {
                    Text("Photos")
                }
            }
            if recipe.servingSize.isNotZero {
                Section {
                    Text(recipe.servingSize.description + " servings")
                } header: {
                    Text("Serving Size")
                }
            }
            if recipe.cookingTime.isNotZero {
                Section {
                    Text(recipe.cookingTime.description + " minutes")
                } header: {
                    Text("Cooking Time")
                }
            }
            if let ingredientObjects = recipe.ingredientObjects,
               ingredientObjects.isNotEmpty {
                Section {
                    ForEach(ingredientObjects.sorted { $0.order < $1.order }, id: \.self) { ingredientObject in
                        HStack {
                            Text(ingredientObject.ingredient?.value ?? "")
                            Spacer()
                            Text(ingredientObject.amount)
                        }
                    }
                } header: {
                    Text("Ingredients")
                }
            }
            if recipe.steps.isNotEmpty {
                Section {
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { values in
                        HStack(alignment: .top) {
                            Text((values.offset + 1).description + ".")
                                .frame(width: 24)
                            Text(values.element)
                        }
                    }
                } header: {
                    Text("Steps")
                }
            }
            if !isSubscribeOn {
                AdvertisementSection(.medium)
            }
            if let categories = recipe.categories,
               categories.isNotEmpty {
                Section {
                    ForEach(categories, id: \.self) {
                        Text($0.value)
                    }
                } header: {
                    Text("Categories")
                }
            }
            if recipe.note.isNotEmpty {
                Section {
                    Text(recipe.note)
                } header: {
                    Text("Note")
                }
            }
            if let diaries = recipe.diaries,
               diaries.isNotEmpty {
                Section {
                    ForEach(diaries) {
                        Text($0.date.formatted(.dateTime.year().month().day()))
                    }
                } header: {
                    Text("Diaries")
                }
            }
            Section {
                Text(recipe.createdTimestamp.formatted(.dateTime.year().month().day()))
            } header: {
                Text("Created At")
            }
            Section {
                Text(recipe.modifiedTimestamp.formatted(.dateTime.year().month().day()))
            } header: {
                Text("Updated At")
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
