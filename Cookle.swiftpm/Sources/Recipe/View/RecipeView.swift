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

    var body: some View {
        List {
            Section("Photos") {
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(recipe.photos, id: \.self) { photo in
                            if let image = UIImage(data: photo) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 120)
                            }
                        }
                    }
                }
            }
            Section("Serving Size") {
                Text(recipe.servingSize.description + " servings")
            }
            Section("Cooking Time") {
                Text(recipe.cookingTime.description + " minutes")
            }
            Section("Ingredients") {
                ForEach(recipe.ingredientObjects.sorted { $0.order < $1.order }, id: \.self) { ingredientObject in
                    HStack {
                        Text(ingredientObject.ingredient.value)
                        Spacer()
                        Text(ingredientObject.amount)
                    }
                }
            }
            Section("Steps") {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { values in
                    HStack(alignment: .top) {
                        Text((values.offset + 1).description + ".")
                            .frame(width: 24)
                        Text(values.element)
                    }
                }
            }
            Section {
                Advertisement(.medium)
            }
            Section("Categories") {
                ForEach(recipe.categories, id: \.self) {
                    Text($0.value)
                }
            }
            Section("Note") {
                Text(recipe.note)
            }
            Section("Diaries") {
                ForEach(recipe.diaries) {
                    Text($0.date.formatted(.dateTime.year().month().day()))
                }
            }
            Section("Created At") {
                Text(recipe.createdTimestamp.formatted(.dateTime.year().month().day()))
            }
            Section("Updated At") {
                Text(recipe.modifiedTimestamp.formatted(.dateTime.year().month().day()))
            }
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
