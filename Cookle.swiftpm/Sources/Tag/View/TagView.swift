//
//  TagView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import SwiftUI

struct TagView<T: Tag>: View {
    @Environment(T.self) private var tag

    @Binding private var recipe: Recipe?

    init(selection: Binding<Recipe?> = .constant(nil)) {
        _recipe = selection
    }

    var body: some View {
        List(selection: $recipe) {
            Section {
                Text(tag.value)
            } header: {
                Text("Value")
            }
            Section {
                ForEach(tag.recipes.orEmpty, id: \.self) { recipe in
                    NavigationLink(selection: .recipe(recipe)) {
                        Text(recipe.name)
                    }
                }
            } header: {
                Text("Recipes")
            }
            Section {
                Text(tag.createdTimestamp.formatted(.dateTime.year().month().day()))
            } header: {
                Text("Created At")
            }
            Section {
                Text(tag.modifiedTimestamp.formatted(.dateTime.year().month().day()))
            } header: {
                Text("Updated At")
            }
        }
        .navigationTitle(tag.value)
        .toolbar {
            ToolbarItem {
                EditTagButton<T>()
            }
        }
    }
}

#Preview {
    CooklePreview { preview in
        NavigationStack {
            TagView<Ingredient>()
                .environment(preview.ingredients[0])
        }
    }
}
