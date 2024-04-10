//
//  DiaryView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import SwiftUI
import SwiftData

struct DiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TagStore.self) private var tagStore

    @Query private var recipes: [Recipe]

    @State private var content: Tag?
    @State private var detail: Recipe?

    var body: some View {
        NavigationSplitView {
            List(tagStore.tags.filter { $0.type == .yearMonth }, id: \.self, selection: $content) {
                Text($0.name)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: deleteAllRecipes) {
                        Label("Delete All", systemImage: "trash")
                    }
                }
                ToolbarItem {
                    Button(action: addRecipe) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } content: {
            if let content {
                List(recipes.filter { $0.yearMonth == content.name }, id: \.self, selection: $detail) { recipe in
                    Text(recipe.name)
                }
            }
        } detail: {
            if let detail {
                RecipeView()
                    .environment(detail)
            }
        }
        .onAppear {
            tagStore.modify(recipes)
        }
    }

    private func deleteAllRecipes() {
        withAnimation {
            recipes.forEach(modelContext.delete)
        }
    }

    private func addRecipe() {
        withAnimation {
            let recipe = Recipe()
            modelContext.insert(recipe)
            tagStore.insert(.init(type: .name, name: recipe.name))
            tagStore.insert(.init(type: .category, name: recipe.tag))
            tagStore.insert(.init(type: .year, name: recipe.year))
            tagStore.insert(.init(type: .yearMonth, name: recipe.yearMonth))
        }
    }
}

#Preview {
    DiaryView()
        .modelContainer(for: Recipe.self, inMemory: true)
        .environment(TagStore())
}
