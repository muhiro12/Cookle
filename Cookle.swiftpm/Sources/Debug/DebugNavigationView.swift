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
    @Query(DiaryObject.descriptor) private var diaryObjects: [DiaryObject]
    @Query(Recipe.descriptor) private var recipes: [Recipe]
    @Query(IngredientObject.descriptor) private var ingredientObjects: [IngredientObject]
    @Query(Ingredient.descriptor) private var ingredients: [Ingredient]
    @Query(Category.descriptor) private var categories: [Category]

    @State private var content: DebugContent?
    @State private var detail: Int?

    var body: some View {
        NavigationSplitView {
            DebugRootView(selection: $content)
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
            if let content {
                DebugContentView(content, selection: $detail)
                    .navigationTitle("Content")
            }
        } detail: {
            if let detail,
               let content {
                DebugDetailView(detail, content: content)
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
