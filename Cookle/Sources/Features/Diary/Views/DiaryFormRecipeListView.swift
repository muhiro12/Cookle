//
//  DiaryFormRecipeListView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/30/24.
//

import MHUI
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
    @State private var isRegistrationPresented = false

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
            .sheet(isPresented: $isRegistrationPresented) {
                DiaryRecipeRegistrationView { recipe in
                    temporarySelection.insert(recipe)
                }
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button("Register New Recipe", systemImage: "plus") {
                        isRegistrationPresented = true
                    }
                }
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
        if recipes.isEmpty {
            ContentUnavailableView {
                Label("No Recipes Yet", systemImage: "book.pages")
            } description: {
                Text("Add a recipe to start building your collection.")
            }
        } else {
            recipeList
        }
    }

    var recipeList: some View {
        List(selection: $temporarySelection) {
            Section {
                if selectedRecipes.isEmpty {
                    Text("Choose recipes from the list below.")
                        .foregroundStyle(.secondary)
                } else {
                    recipeRows(selectedRecipes)
                }
            } header: {
                Text("Selected (\(selectedRecipes.count))")
            }

            Section {
                if candidateRecipes.isEmpty {
                    if searchText.isEmpty {
                        Text("All recipes are selected.")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No matching recipes.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    recipeRows(candidateRecipes)
                }
            } header: {
                Text("Add Recipes")
            }
        }
        .mhListChrome()
    }

    var selectedRecipes: [Recipe] {
        recipes.filter { recipe in
            temporarySelection.contains(recipe)
        }
    }

    var candidateRecipes: [Recipe] {
        recipes.filter { recipe in
            guard !temporarySelection.contains(recipe) else {
                return false
            }
            guard !searchText.isEmpty else {
                return true
            }
            return recipe.name.normalizedContains(searchText)
        }
    }

    func recipeRows(_ recipes: [Recipe]) -> some View {
        ForEach(recipes) { recipe in
            RecipeLabel()
                .labelStyle(.titleAndLargeIcon)
                .tag(recipe)
                .environment(recipe)
        }
    }
}

#if DEBUG
#Preview("No selection") {
    DiaryRecipeSelectionPreview(selectedCount: 0)
        .cooklePreviewAppAssembly(DiaryRecipeSelectionPreview.assembly)
}

#Preview("Selected recipes") {
    DiaryRecipeSelectionPreview(selectedCount: 2)
        .cooklePreviewAppAssembly(DiaryRecipeSelectionPreview.assembly)
}

#Preview("All selected") {
    DiaryRecipeSelectionPreview(selectedCount: 5)
        .cooklePreviewAppAssembly(DiaryRecipeSelectionPreview.assembly)
}
#endif
