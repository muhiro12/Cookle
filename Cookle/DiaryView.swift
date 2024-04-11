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
    @State private var isPresented = false

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
                    Button("Delete All", systemImage: "trash") {
                        withAnimation {
                            recipes.forEach(modelContext.delete)
                        }
                    }
                }
                ToolbarItem {
                    Button("Add Random Recipe", systemImage: "dice") {
                        withAnimation {
                            let recipe = PreviewData.randomRecipe()
                            modelContext.insert(recipe)
                            tagStore.insert(with: recipe)
                        }
                    }
                }
                ToolbarItem {
                    Button("Add Recipe", systemImage: "plus") {
                        isPresented = true
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
        .sheet(isPresented: $isPresented) {
            RecipeCreateView()
        }
    }
}

#Preview {
    DiaryView()
        .modelContainer(PreviewData.modelContainer)
        .environment(PreviewData.tagStore)
}
