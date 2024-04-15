//
//  DebugRootView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import SwiftUI
import SwiftData

struct DebugRootView: View {
    @Query private var diaries: [Diary]
    @Query private var recipes: [Recipe]
    @Query private var ingredients: [Ingredient]
    @Query private var categories: [Category]

    @State private var content: Int?
    @State private var detail: Int?

    private var list: [any PersistentModel] {
        switch content {
        case 0:
            diaries
        case 1:
            recipes
        case 2:
            ingredients
        case 3:
            categories
        default:
            []
        }
    }

    var body: some View {
        NavigationSplitView {
            List(0..<4, selection: $content) { content in
                switch content {
                case 0:
                    Text("Diaries")
                case 1:
                    Text("Recipes")
                case 2:
                    Text("Ingredients")
                case 3:
                    Text("Categories")
                default:
                    Text("")
                }
            }
            .navigationTitle("Debug")
        } content: {
            List(Array(list.enumerated()), id: \.0, selection: $detail) {
                switch $0.1 {
                case let value as Diary:
                    Text(value.date.formatted())
                case let value as Recipe:
                    Text(value.name)
                case let value as Ingredient:
                    Text(value.value)
                case let value as Category:
                    Text(value.value)
                default:
                    Text("")
                }
            }
            .navigationTitle("Content")
        } detail: {
            if let detail {
                Group {
                    switch list[detail] {
                    case let value as Diary:
                        DiaryView()
                            .environment(value)
                    case let value as Recipe:
                        RecipeView()
                            .environment(value)
                    case let value as Ingredient:
                        TagView<Ingredient>()
                            .environment(value)
                    case let value as Category:
                        TagView<Category>()
                            .environment(value)
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
    DebugRootView()
}
