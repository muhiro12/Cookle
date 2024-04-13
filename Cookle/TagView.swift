//
//  TagView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import SwiftUI
import SwiftData

struct TagView: View {
    @Environment(TagStore.self) private var tagStore

    @Query private var recipes: [Recipe]

    @State private var content: Tag?
    @State private var detail: Recipe?
    @State private var isGrid = true

    var body: some View {
        NavigationSplitView {
            VStack {
                ScrollView {
                    LazyVGrid(columns: (0..<3).map { _ in .init() }) {
                        ForEach(tagStore.customTagList) { tag in
                            Button(tag.value) {
                                content = tag
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                List(selection: $content) {}
                    .frame(height: .zero)
            }
            .toolbar {
                ToolbarItem {
                    AddRecipeButton()
                }
            }
            .navigationTitle("Tag")
        } content: {
            if let content {
                VStack {
                    if isGrid {
                        RecipeGridView(recipes.filter { $0.tagList.contains(content.value) },
                                       selection: $detail)
                    } else {
                        RecipeListView(recipes.filter { $0.tagList.contains(content.value) },
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
                .navigationTitle(content.value)
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
    TagView()
        .modelContainer(PreviewData.modelContainer)
        .environment(PreviewData.tagStore)
}
