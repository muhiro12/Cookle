//
//  TagRootView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import SwiftUI
import SwiftData

struct TagRootView<T: Tag>: View {
    @Query private var tags: [T]

    @State private var content: T?
    @State private var detail: Recipe?
    @State private var isGrid = true

    var body: some View {
        NavigationSplitView {
            VStack {
                ScrollView {
                    LazyVGrid(columns: (0..<3).map { _ in .init() }) {
                        ForEach(tags) { tag in
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
            .navigationTitle(String(describing: T.self))
        } content: {
            if let content {
                VStack {
                    if isGrid {
                        RecipeGridView(content.recipes, selection: $detail)
                    } else {
                        RecipeListView(content.recipes, selection: $detail)
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
    ModelContainerPreview { _ in
        TagRootView<Category>()
    }
}
