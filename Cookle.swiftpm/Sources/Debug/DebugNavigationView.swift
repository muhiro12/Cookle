//
//  DebugNavigationView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import SwiftUI
import SwiftData

struct DebugNavigationView: View {
    @Environment(\.modelContext) private var context

    @Query(Diary.descriptor) private var diaries: [Diary]
    @Query(Recipe.descriptor) private var recipes: [Recipe]
    @Query(IngredientObject.descriptor) private var ingredientObjects: [IngredientObject]
    @Query(Ingredient.descriptor) private var ingredients: [Ingredient]
    @Query(Category.descriptor) private var categories: [Category]

    @State private var content: Int?
    @State private var detail: Int?

    private let diary = 0
    private let recipe = 1
    private let ingredientObject = 2
    private let ingredient = 3
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
                    case ingredientObject:
                        Text("IngredientObjects")
                    case ingredient:
                        Text("Ingredients")
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
                            ingredientObjects.forEach { context.delete($0) }
                            ingredients.forEach { context.delete($0) }
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
                        case ingredientObject:
                            ingredientObjects.endIndex
                        case ingredient:
                            ingredients.endIndex
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
                    case ingredientObject:
                        Text(ingredientObjects[$0].ingredient.value + " " + ingredientObjects[$0].amount)
                    case ingredient:
                        Text(ingredients[$0].value)
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
                            case ingredientObject:
                                context.delete(ingredientObjects[index])
                            case ingredient:
                                context.delete(ingredients[index])
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
                    case ingredientObject:
                        IngredientObjectView()
                            .environment(ingredientObjects[detail])
                    case ingredient:
                        TagView<Ingredient>()
                            .environment(ingredients[detail])
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
        DebugNavigationView()
    }
}
