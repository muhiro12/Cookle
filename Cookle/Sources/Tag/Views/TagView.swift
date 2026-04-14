//
//  TagView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import SwiftData
import SwiftUI

struct TagView<T: Tag>: View {
    @Environment(T.self)
    private var tag

    @Binding private var recipe: Recipe?

    var body: some View {
        List {
            recipeSection
            createdAtSection
            updatedAtSection
            actionSection
        }
        .navigationTitle(tag.value)
        .toolbar {
            ToolbarItem {
                EditTagButton<T>()
            }
        }
    }

    init(selection: Binding<Recipe?> = .constant(nil)) {
        _recipe = selection
    }
}

private extension TagView {
    var recipeSection: some View {
        Section {
            ForEach(tag.recipes.orEmpty) { recipe in
                Button {
                    self.recipe = recipe
                } label: {
                    RecipeLabel()
                        .labelStyle(.titleAndLargeIcon)
                        .environment(recipe)
                        .cookleButtonRowContent()
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Recipes")
        }
    }

    var createdAtSection: some View {
        Section {
            Text(tag.createdTimestamp.formatted(.dateTime.year().month().day()))
        } header: {
            Text("Created At")
        }
    }

    var updatedAtSection: some View {
        Section {
            Text(tag.modifiedTimestamp.formatted(.dateTime.year().month().day()))
        } header: {
            Text("Updated At")
        }
    }

    var actionSection: some View {
        Section {
            EditTagButton<T>()
            DeleteTagButton<T>()
        } header: {
            Spacer()
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var ingredients: [Ingredient]
    NavigationStack {
        TagView<Ingredient>()
            .environment(ingredients[0])
    }
}
