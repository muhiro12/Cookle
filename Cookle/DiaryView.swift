//
//  DiaryView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import SwiftUI
import SwiftData

struct DiaryView<Content: Tag>: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.inMemoryContext) private var inMemoryContext

    @Query private var recipes: [Recipe]

    @State private var content: Content.ID?
    @State private var detail: Recipe?
    @State private var isGrid = true

    var body: some View {
        NavigationSplitView {
            List(inMemoryContext.yearMonthList, selection: $content) { yearMonthTag in
                Section(yearMonthTag.value) {
                    ForEach(inMemoryContext.yearMonthDayList.filter { $0.value.contains(yearMonthTag.value) }) { yearMonthDayTag in
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
                            inMemoryContext.insert(with: recipe)
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
                        RecipeGridView(recipes.filter { $0.yearMonthDay == inMemoryContext.yearMonthDayList.first { $0.id as? Content.ID == content }?.value },
                                       selection: $detail)
                    } else {
                        RecipeListView(recipes.filter { $0.yearMonthDay == inMemoryContext.yearMonthDayList.first { $0.id as? Content.ID == content }?.value },
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
                .navigationTitle(inMemoryContext.yearMonthDayList.first { $0.id as? Content.ID == content }?.value ?? "")
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
    DiaryView<YearMonthDay>()
        .modelContainer(PreviewData.modelContainer)
        .environment(\.inMemoryContext, PreviewData.inMemoryContext)
}
