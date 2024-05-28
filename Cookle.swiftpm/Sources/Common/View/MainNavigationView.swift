//
//  MainNavigationView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/28.
//

import SwiftUI

struct MainNavigationView: View {
    @AppStorage(.isDebugOn) private var isDebugOn

    @State private var content: MainNavigationSidebar?
    @State private var item: AnyHashable?
    @State private var detail: Recipe?

    @State private var isDebugPresented = false

    var body: some View {
        NavigationSplitView() {
            List(selection: $content) {
                Label("Diary", systemImage: "book")
                    .tag(MainNavigationSidebar.diary)
                Label("Recipe", systemImage: "book.pages")
                    .tag(MainNavigationSidebar.recipe)
                Label("Ingredient", systemImage: "refrigerator")
                    .tag(MainNavigationSidebar.ingredient)
                Label("Category", systemImage: "frying.pan")
                    .tag(MainNavigationSidebar.category)
            }
            .toolbar {
                if isDebugOn {
                    ToolbarItem {
                        Button("Debug", systemImage: "flask") {
                            isDebugPresented = true
                        }
                    }
                }
            }
            .navigationTitle("Cookle")
        } content: {
            NavigationStack {
                Group {
                    switch content {
                    case .diary:
                        DiaryListView(selection: .init(
                            get: { item as? Diary },
                            set: { item = $0 }
                        ))
                        .toolbar {
                            ToolbarItem {
                                AddDiaryButton()
                            }
                            ToolbarItem {
                                AddRecipeButton()
                            }
                        }
                        .navigationTitle("Diary")
                    case .recipe:
                        RecipeListView(selection: $detail)
                            .toolbar {
                                ToolbarItem {
                                    AddRecipeButton()
                                }
                            }
                            .navigationTitle("Recipe")
                    case .ingredient:
                        TagListView(selection: .init(
                            get: { item as? Ingredient },
                            set: { item = $0 }
                        ))
                        .toolbar {
                            ToolbarItem {
                                AddRecipeButton()
                            }
                        }
                        .navigationTitle("Ingredient")
                    case .category:
                        TagListView(selection: .init(
                            get: { item as? Category },
                            set: { item = $0 }
                        ))
                        .toolbar {
                            ToolbarItem {
                                AddRecipeButton()
                            }
                        }
                        .navigationTitle("Category")
                    default:
                        EmptyView()
                    }
                }
                .navigationDestination(item: $item) { item in
                    switch item {
                    case let diary as Diary:
                        DiaryView(selection: $detail)
                            .toolbar {
                                ToolbarItem(placement: .destructiveAction) {
                                    DeleteDiaryButton()
                                }
                                ToolbarItem(placement: .confirmationAction) {
                                    EditDiaryButton()
                                }
                            }
                            .navigationTitle(diary.date.formatted(.dateTime.year().month().day()))
                            .environment(diary)
                    case let ingredient as Ingredient:
                        TagView<Ingredient>(selection: $detail)
                            .toolbar {
                                ToolbarItem {
                                    EditTagButton<Ingredient>()
                                }
                            }
                            .navigationTitle(ingredient.value)
                            .environment(ingredient)
                    case let category as Category:
                        TagView<Category>(selection: $detail)
                            .toolbar {
                                ToolbarItem {
                                    EditTagButton<Category>()
                                }
                            }
                            .navigationTitle(category.value)
                            .environment(category)
                    default:
                        EmptyView()
                    }
                }
            }
        } detail: {
            if let detail {
                RecipeView()
                    .toolbar {
                        ToolbarItem(placement: .destructiveAction) {
                            DeleteRecipeButton()
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            EditRecipeButton()
                        }
                    }
                    .navigationTitle(detail.name)
                    .environment(detail)
            }
        }
        .sheet(isPresented: $isDebugPresented) {
            DebugNavigationView()
        }
    }
}

#Preview {
    ModelContainerPreview { _ in
        MainNavigationView()
    }
}
