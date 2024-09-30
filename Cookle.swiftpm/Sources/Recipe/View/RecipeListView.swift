//
//  RecipeListView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/13.
//

import SwiftData
import SwiftUI
import SwiftUtilities

struct RecipeListView: View {
    @Environment(\.isPresented) private var isPresented

    @Query private var recipes: [Recipe]

    @Binding private var recipe: Recipe?

    @State private var searchText = ""

    init(selection: Binding<Recipe?> = .constant(nil), descriptor: FetchDescriptor<Recipe> = .recipes(.all)) {
        _recipe = selection
        _recipes = .init(descriptor)
    }

    var body: some View {
        List(recipes, selection: $recipe) { recipe in
            NavigationLink(value: recipe) {
                RecipeLabel()
                    .labelStyle(.titleAndLargeIcon)
                    .environment(recipe)
            }
            .hidden(searchText.isNotEmpty && !recipe.name.normalizedContains(searchText))
        }
        .searchable(text: $searchText)
        .navigationTitle(Text("Recipes"))
        .toolbar {
            ToolbarItem {
                AddRecipeButton()
            }
            ToolbarItem {
                CloseButton()
                    .hidden(!isPresented)
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        NavigationStack {
            RecipeListView()
        }
    }
}

struct ShortTitleLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.title
    }
}
