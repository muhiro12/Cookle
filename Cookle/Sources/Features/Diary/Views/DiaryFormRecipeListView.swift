//
//  DiaryFormRecipeListView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/30/24.
//

import SwiftData
import SwiftUI

struct DiaryFormRecipeListView: View {
    @Environment(\.dismiss)
    private var dismiss

    @Query(.recipes(.all))
    private var recipes: [Recipe]

    @Binding private var selection: Set<Recipe>

    @State private var temporarySelection = Set<Recipe>()
    @State private var searchText = ""
    @State private var isSearchPresented = false

    private let type: DiaryObjectType

    var body: some View {
        contentView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(\.editMode, .constant(.active))
            .navigationTitle(type.title)
            .searchable(
                text: $searchText,
                isPresented: $isSearchPresented,
                prompt: Text("Search")
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .toolbar {
                ToolbarItem {
                    Button {
                        selection = temporarySelection
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
    }

    init(selection: Binding<Set<Recipe>>, type: DiaryObjectType) {
        _selection = selection
        _temporarySelection = .init(initialValue: selection.wrappedValue)
        self.type = type
    }
}

private extension DiaryFormRecipeListView {
    @ViewBuilder var contentView: some View {
        if !filteredRecipes.isEmpty {
            recipeList
        } else {
            emptyStateView
        }
    }

    var recipeList: some View {
        List(
            filteredRecipes,
            selection: $temporarySelection
        ) { recipe in
            RecipeLabel()
                .labelStyle(.titleAndLargeIcon)
                .tag(recipe)
                .environment(recipe)
        }
    }

    @ViewBuilder var emptyStateView: some View {
        if !recipes.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            ContentUnavailableView {
                Label("No Recipes Yet", systemImage: "book.pages")
            } description: {
                Text("Add a recipe to start building your collection.")
            }
        }
    }

    var filteredRecipes: [Recipe] {
        recipes.filter { recipe in
            guard !searchText.isEmpty else {
                return true
            }
            return recipe.name.normalizedContains(searchText)
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        DiaryFormRecipeListView(
            selection: .constant([]),
            type: .dinner
        )
    }
}
