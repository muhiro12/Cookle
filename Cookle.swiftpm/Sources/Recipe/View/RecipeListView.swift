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
        List(recipes, id: \.self, selection: $recipe) { recipe in
            if recipe.name.normalizedContains(searchText)
                || searchText.isEmpty {
                NavigationLink(value: recipe) {
                    Label {
                        Text(recipe.name)
                    } icon: {
                        if let data = recipe.photos?.first?.data,
                           let image = UIImage(data: data) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        } else {
                            Color.clear
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle(Text("Recipes"))
        .toolbar {
            ToolbarItem {
                AddRecipeButton()
            }
            if isPresented {
                ToolbarItem {
                    CloseButton()
                }
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
