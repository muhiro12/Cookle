//
//  MainNavigationContentView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/28.
//

import SwiftUI

struct MainNavigationContentView: View {
    @Binding private var selection: Recipe?

    @State private var item: AnyHashable?

    private var sidebar: MainNavigationSidebar

    init(_ content: MainNavigationSidebar, selection: Binding<Recipe?>) {
        self.sidebar = content
        self._selection = selection
    }

    var body: some View {
        NavigationStack {
            Group {
                switch sidebar {
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
                    RecipeListView(selection: $selection)
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
                }
            }
            .navigationDestination(item: $item) { item in
                switch item {
                case let diary as Diary:
                    DiaryView(selection: $selection)
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
                    TagView<Ingredient>(selection: $selection)
                        .toolbar {
                            ToolbarItem {
                                EditTagButton<Ingredient>()
                            }
                        }
                        .navigationTitle(ingredient.value)
                        .environment(ingredient)
                case let category as Category:
                    TagView<Category>(selection: $selection)
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
    }
}

#Preview {
    ModelContainerPreview { _ in
        MainNavigationContentView(.diary, selection: .constant(nil))
    }
}
