//
//  DebugRootView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import SwiftUI
import SwiftData

struct DebugRootView: View {
    @Environment(\.modelContext) private var context

    @Query private var diaries: [Diary]
    @Query private var recipes: [Recipe]
    @Query private var ingredients: [Ingredient]
    @Query private var recipeIngredients: [RecipeIngredient]
    @Query private var categories: [Category]

    @State private var content: Int?
    @State private var detail: Int?

    private let diary = 0
    private let recipe = 1
    private let ingredient = 2
    private let recipeIngredient = 3
    private let category = 4

    var body: some View {
        NavigationSplitView {
            List(selection: $content) {
                ForEach(0..<5) { content in
                    switch content {
                    case diary:
                        Text("Diaries")
                    case recipe:
                        Text("Recipes")
                    case ingredient:
                        Text("Ingredients")
                    case recipeIngredient:
                        Text("recipeIngredients")
                    case category:
                        Text("Categories")
                    default:
                        EmptyView()
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button("Delete All", systemImage: "trash") {
                        withAnimation {
                            diaries.forEach { context.delete($0) }
                            recipes.forEach { context.delete($0) }
                            ingredients.forEach { context.delete($0) }
                            recipeIngredients.forEach { context.delete($0) }
                            categories.forEach { context.delete($0) }
                        }
                    }
                }
                ToolbarItem {
                    Button("Add Random Diary", systemImage: "dice") {
                        withAnimation {
                            _ = ModelContainerPreview { _ in EmptyView() }.randomDiary(context)
                        }
                    }
                }
            }
            .navigationTitle("Debug")
        } content: {
            List(selection: $detail) {
                ForEach(
                    0..<{
                        switch content {
                        case diary:
                            diaries.endIndex
                        case recipe:
                            recipes.endIndex
                        case ingredient:
                            ingredients.endIndex
                        case recipeIngredient:
                            recipeIngredients.endIndex
                        case category:
                            categories.endIndex
                        default:
                                .zero
                        }
                    }(),
                    id: \.self
                ) {
                    switch content {
                    case diary:
                        Text(diaries[$0].date.formatted())
                    case recipe:
                        Text(recipes[$0].name)
                    case ingredient:
                        Text(ingredients[$0].value)
                    case recipeIngredient:
                        Text(recipeIngredients[$0].ingredient.value + " " + recipeIngredients[$0].amount)
                    case category:
                        Text(categories[$0].value)
                    default:
                        EmptyView()
                    }
                }
                .onDelete { indexSet in
                    withAnimation {
                        indexSet.forEach { index in
                            switch content {
                            case diary:
                                context.delete(diaries[index])
                            case recipe:
                                context.delete(recipes[index])
                            case ingredient:
                                context.delete(ingredients[index])
                            case recipeIngredient:
                                context.delete(recipeIngredients[index])
                            case category:
                                context.delete(categories[index])
                            default:
                                break
                            }
                        }
                    }
                }
            }
            .navigationTitle("Content")
        } detail: {
            if let detail {
                Group {
                    switch content {
                    case diary:
                        DiaryView(selection: .constant(nil))
                            .environment(diaries[detail])
                    case recipe:
                        RecipeView()
                            .environment(recipes[detail])
                    case ingredient:
                        TagView<Ingredient>()
                            .environment(ingredients[detail])
                    case recipeIngredient:
                        // TODO: Make recipeIngredientView
                        EmptyView()
                    case category:
                        TagView<Category>()
                            .environment(categories[detail])
                    default:
                        EmptyView()
                    }
                }
                .navigationTitle("Detail")
            }
        }
    }
}

#Preview {
    ModelContainerPreview { _ in
        DebugRootView()
    }
}
