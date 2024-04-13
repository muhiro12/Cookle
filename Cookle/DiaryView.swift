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
    @State private var isGrid = true

    var body: some View {
        NavigationSplitView {
            List(tagStore.yearMonthTagList, selection: $content) { yearMonthTag in
                Section(yearMonthTag.value) {
                    ForEach(tagStore.yearMonthDayTagList.filter { $0.value.contains(yearMonthTag.value) }) { yearMonthDayTag in
                        Text(yearMonthDayTag.value)
                    }
                }
            }
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
                    AddRecipeButton()
                }
            }
            .navigationTitle("Diary")
        } content: {
            if let content {
                VStack {
                    if isGrid{
                        RecipeGridView(recipes.filter { $0.yearMonthDay == tagStore.yearMonthDayTagList.first { $0.id == content }?.value },
                                       selection: $detail)
                    } else {
                        RecipeListView(recipes.filter { $0.yearMonthDay == tagStore.yearMonthDayTagList.first { $0.id == content }?.value },
                                       selection: $detail)
                    }
                    List(selection: $detail) {}
                        .frame(height: .zero)
                }
                .toolbar {
                    ToolbarItem {
                        ToggleListStyleButton(isGrid: $isGrid)
                    }
                    ToolbarItem {
                        AddRecipeButton()
                    }
                }
                .navigationTitle(tagStore.yearMonthDayTagList.first { $0.id == content }?.value ?? "")
            }
        } detail: {
            if let detail {
                RecipeView()
                    .toolbar {
                        ToolbarItem {
                            EditRecipeButton()
                        }
                    }
                    .navigationTitle(detail.name)
                    .environment(detail)
            }
        }
    }
}

#Preview {
    DiaryView()
        .modelContainer(PreviewData.modelContainer)
        .environment(PreviewData.tagStore)
}
