//
//  TagView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import SwiftData
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
                ForEach(tag.recipes.orEmpty) { recipe in
                    NavigationLink(value: recipe) {
                        RecipeLabel()
                            .labelStyle(.titleAndLargeIcon)
                            .environment(recipe)
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
            Section {
                EditTagButton<T>()
                DeleteTagButton<T>()
            } header: {
                Spacer()
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

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var ingredients: [Ingredient]
    NavigationStack {
        TagView<Ingredient>()
            .environment(ingredients[0])
    }
}
