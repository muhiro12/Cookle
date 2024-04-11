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

    @State private var content: Tag.ID?
    @State private var detail: Recipe?
    @State private var isExpanded = true

    var body: some View {
        NavigationSplitView {
            List(tagStore.tags.filter { $0.type == .year }, selection: $content) { yearTag in
                Section(yearTag.value, isExpanded: $isExpanded) {
                    ForEach(tagStore.tags.filter { $0.type == .yearMonth && $0.value.contains(yearTag.value) }) { yearMonthTag in
                        Text(yearMonthTag.value)
                    }
                }
            }
            .listStyle(.sidebar)
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
                List(recipes.filter { $0.yearMonth == tagStore.tags.first { $0.id == content }?.value }, id: \.self, selection: $detail) { recipe in
                    Text(recipe.name)
                }
            }
        } detail: {
            if let detail {
                RecipeView()
                    .environment(detail)
            }
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
            tagStore.insert(with: recipe)
        }
    }
}

#Preview {
    DiaryView()
        .modelContainer(PreviewData.modelContainer)
        .environment(PreviewData.tagStore)
}
