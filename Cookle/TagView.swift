//
//  TagView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import SwiftUI
import SwiftData

struct TagView<T: Tag>: View {
    @Environment(\.inMemoryContext) private var inMemoryContext

    @Query private var recipes: [Recipe]

    @State private var content: T?
    @State private var detail: Recipe?
    @State private var isGrid = true

    private var filteredRecipes: [Recipe] {
        recipes.filter { recipe in
            {
                switch T.self {
                case is Name.Type:
                    return [recipe.name]
                case is YearMonth.Type:
                    return [recipe.yearMonth]
                case is YearMonthDay.Type:
                    return [recipe.yearMonthDay]
                case is Ingredient.Type:
                    return recipe.ingredientList
                case is Instruction.Type:
                    return recipe.instructionList
                case is Category.Type:
                    return recipe.categoryList
                default:
                    return []
                }
            }().contains(content?.value ?? "")
        }
    }

    var body: some View {
        NavigationSplitView {
            VStack {
                ScrollView {
                    LazyVGrid(columns: (0..<3).map { _ in .init() }) {
                        ForEach(inMemoryContext.tagList()) { (tag: T) in
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
                        RecipeGridView(filteredRecipes, selection: $detail)
                    } else {
                        RecipeListView(filteredRecipes, selection: $detail)
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
    TagView<Category>()
        .modelContainer(PreviewData.modelContainer)
        .environment(\.inMemoryContext, PreviewData.inMemoryContext)
}
