//
//  MainNavigationContentView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/28.
//

import SwiftUI

struct MainNavigationContentView: View {
    @Binding private var selection: Recipe?

    @State private var path = NavigationPath()

    private var sidebar: MainNavigationSidebar

    init(_ content: MainNavigationSidebar, selection: Binding<Recipe?>) {
        self.sidebar = content
        self._selection = selection
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                switch sidebar {
                case .diary:
                    DiaryListView(selection: pathSelection())
                        .toolbar {
                            ToolbarItem {
                                AddDiaryButton()
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
                    TagListView<Ingredient>(selection: pathSelection())
                        .toolbar {
                            ToolbarItem {
                                AddRecipeButton()
                            }
                        }
                        .navigationTitle("Ingredient")

                case .category:
                    TagListView<Category>(selection: pathSelection())
                        .toolbar {
                            ToolbarItem {
                                AddRecipeButton()
                            }
                        }
                        .navigationTitle("Category")
                case .photo:
                    PhotoListView()
                        .navigationTitle("Photo")
                }
            }
            .navigationDestination(for: Diary.self) { diary in
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
            }
            .navigationDestination(for: Ingredient.self) { ingredient in
                TagView<Ingredient>(selection: $selection)
                    .toolbar {
                        ToolbarItem {
                            EditTagButton<Ingredient>()
                        }
                    }
                    .navigationTitle(ingredient.value)
                    .environment(ingredient)
            }
            .navigationDestination(for: Category.self) { category in
                TagView<Category>(selection: $selection)
                    .toolbar {
                        ToolbarItem {
                            EditTagButton<Category>()
                        }
                    }
                    .navigationTitle(category.value)
                    .environment(category)
            }
            .navigationDestination(for: Photo.self) { photo in
                PhotoView(selection: $selection)
                    .navigationTitle("Photo")
                    .environment(photo)
            }
        }
    }

    private func pathSelection<Value: Hashable>() -> Binding<Value?> {
        .init(
            get: { nil },
            set: { value in
                guard let value else {
                    return
                }
                path.append(value)
            }
        )
    }
}

#Preview {
    CooklePreview { _ in
        MainNavigationContentView(.diary, selection: .constant(nil))
    }
}
