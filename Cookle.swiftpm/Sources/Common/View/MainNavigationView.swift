//
//  MainNavigationView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/28.
//

import SwiftUI

struct MainNavigationView: View {
    @AppStorage(.isDebugOn) private var isDebugOn

    @State private var content: Tab?
    @State private var detail: (any Hashable)?

    @State private var isDebugPresented = false

    var body: some View {
        NavigationSplitView {
            List(selection: $content) {
                Label("Diary", systemImage: "book")
                    .tag(Tab.diary)
                Label("Recipe", systemImage: "book.pages")
                    .tag(Tab.recipe)
                Label("Ingredient", systemImage: "refrigerator")
                    .tag(Tab.ingredient)
                Label("Category", systemImage: "frying.pan")
                    .tag(Tab.category)
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
            switch content {
            case .diary:
                DiaryListView(selection: .init(
                    get: { detail as? Diary },
                    set: { detail = $0 }
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
                RecipeListView(selection: .init(
                    get: { detail as? Recipe },
                    set: { detail = $0 }
                ))
                .toolbar {
                    ToolbarItem {
                        AddRecipeButton()
                    }
                }
                .navigationTitle("Recipe")
            case .ingredient:
                TagListView(selection: .init(
                    get: { detail as? Ingredient },
                    set: { detail = $0 }
                ))
                .toolbar {
                    ToolbarItem {
                        AddRecipeButton()
                    }
                }
                .navigationTitle("Ingredient")
            case .category:
                TagListView(selection: .init(
                    get: { detail as? Category },
                    set: { detail = $0 }
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
        } detail: {
            switch detail {
            case let diary as Diary:
                DiaryView(selection: .init(
                    get: { detail as? Recipe },
                    set: {
                        content = .recipe
                        detail = $0
                    }
                ))
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
            case let recipe as Recipe:
                RecipeView()
                    .toolbar {
                        ToolbarItem(placement: .destructiveAction) {
                            DeleteRecipeButton()
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            EditRecipeButton()
                        }
                    }
                    .navigationTitle(recipe.name)
                    .environment(recipe)
            case let ingredient as Ingredient:
                TagView<Ingredient>(selection: .init(
                    get: { detail as? Recipe },
                    set: {
                        content = .recipe
                        detail = $0
                    }
                ))
                .toolbar {
                    ToolbarItem {
                        EditTagButton<Ingredient>()
                    }
                }
                .navigationTitle(ingredient.value)
                .environment(ingredient)
            case let category as Category:
                TagView<Category>(selection: .init(
                    get: { detail as? Recipe },
                    set: {
                        content = .recipe
                        detail = $0
                    }
                ))
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
        .sheet(isPresented: $isDebugPresented) {
            DebugNavigationView()
                .environment(TabController(initialTab: .debug))
        }
    }
}

#Preview {
    ModelContainerPreview { _ in
        MainNavigationView()
    }
}
