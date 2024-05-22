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

    @AppStorage(.isICloudOn) private var isICloudOn
    @AppStorage(.isDebugOn) private var isDebugOn

    @Query(Diary.descriptor) private var diaries: [Diary]
    @Query(DiaryObject.descriptor) private var diaryObjects: [DiaryObject]
    @Query(Recipe.descriptor) private var recipes: [Recipe]
    @Query(IngredientObject.descriptor) private var ingredientObjects: [IngredientObject]
    @Query(Ingredient.descriptor) private var ingredients: [Ingredient]
    @Query(Category.descriptor) private var categories: [Category]

    @State private var content: Int?
    @State private var detail: Int?

    private let diary = 0
    private let diaryObject = 1
    private let recipe = 2
    private let ingredient = 3
    private let ingredientObject = 4
    private let category = 5

    var body: some View {
        NavigationSplitView {
            List(selection: $content) {
                Section {
                    ForEach(diary..<category + 1, id: \.self) { content in
                        switch content {
                        case diary:
                            Text("Diaries")
                        case diaryObject:
                            Text("DiaryObjects")
                        case recipe:
                            Text("Recipes")
                        case ingredient:
                            Text("Ingredients")
                        case ingredientObject:
                            Text("IngredientObjects")
                        case category:
                            Text("Categories")
                        default:
                            EmptyView()
                        }
                    }
                }
                Section {
                    Toggle("iCloud On", isOn: $isICloudOn)
                    Toggle("Debug On", isOn: $isDebugOn)
                }
            }
            .toolbar {
                ToolbarItem {
                    Button("Delete All", systemImage: "trash") {
                        withAnimation {
                            diaries.forEach { context.delete($0) }
                            diaryObjects.forEach { context.delete($0) }
                            recipes.forEach { context.delete($0) }
                            ingredients.forEach { context.delete($0) }
                            ingredientObjects.forEach { context.delete($0) }
                            categories.forEach { context.delete($0) }
                        }
                    }
                }
                ToolbarItem {
                    Button("Add Random Diary", systemImage: "dice") {
                        withAnimation {
                            _ = ModelContainerPreview { _ in
                                EmptyView()
                            }.randomDiary(context)
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
                        case diaryObject:
                            diaryObjects.endIndex
                        case recipe:
                            recipes.endIndex
                        case ingredient:
                            ingredients.endIndex
                        case ingredientObject:
                            ingredientObjects.endIndex
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
                    case diaryObject:
                        Text(diaryObjects[$0].type.debugDescription)
                    case recipe:
                        Text(recipes[$0].name)
                    case ingredient:
                        Text(ingredients[$0].value)
                    case ingredientObject:
                        Text(ingredientObjects[$0].ingredient.value + " " + ingredientObjects[$0].amount)
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
                            case diaryObject:
                                context.delete(diaryObjects[index])
                            case recipe:
                                context.delete(recipes[index])
                            case ingredient:
                                context.delete(ingredients[index])
                            case ingredientObject:
                                context.delete(ingredientObjects[index])
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
                            .toolbar {
                                ToolbarItem {
                                    Menu("Recipes") {
                                        ForEach(diaries[detail].recipes) {
                                            Text($0.name)
                                        }
                                    }
                                }
                            }
                            .environment(diaries[detail])
                    case diaryObject:
                        DiaryObjectView()
                            .environment(diaryObjects[detail])
                    case recipe:
                        RecipeView()
                            .environment(recipes[detail])
                    case ingredient:
                        TagView<Ingredient>()
                            .toolbar {
                                ToolbarItem {
                                    Menu("Objects") {
                                        ForEach(ingredients[detail].objects) {
                                            Text($0.amount)
                                        }
                                    }
                                }
                            }
                            .environment(ingredients[detail])
                    case ingredientObject:
                        IngredientObjectView()
                            .environment(ingredientObjects[detail])
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
