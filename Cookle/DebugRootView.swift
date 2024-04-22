//
//  DebugRootView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import SwiftUI
import SwiftData

struct DebugRootView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var diaries: [Diary]
    @Query private var recipes: [Recipe]
    @Query private var ingredients: [Ingredient]
    @Query private var categories: [Category]

    @State private var content: Int?
    @State private var detail: Int?

    private let diary = 0
    private let recipe = 1
    private let ingredient = 2
    private let category = 3

    var body: some View {
        NavigationSplitView {
            List(selection: $content) {
                ForEach(0..<4) { content in
                    switch content {
                    case diary:
                        Text("Diaries")
                    case recipe:
                        Text("Recipes")
                    case ingredient:
                        Text("Ingredients")
                    case category:
                        Text("Categories")
                    default:
                        EmptyView()
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
                                modelContext.delete(diaries[index])
                            case recipe:
                                modelContext.delete(recipes[index])
                            case ingredient:
                                modelContext.delete(ingredients[index])
                            case category:
                                modelContext.delete(categories[index])
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
                        DiaryView()
                            .environment(diaries[detail])
                    case recipe:
                        RecipeView()
                            .environment(recipes[detail])
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
        DebugRootView()
    }
}
