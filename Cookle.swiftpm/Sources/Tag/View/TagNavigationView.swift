//
//  TagNavigationView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import SwiftUI
import SwiftData

struct TagNavigationView<T: Tag>: View {
    @Query(T.descriptor) private var tags: [T]

    @State private var content: T?
    @State private var detail: Recipe?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            TagListView(tags, selection: $content)
                .toolbar {
                    ToolbarItem {
                        AddRecipeButton()
                    }
                }
                .navigationTitle(String(describing: T.self))
        } content: {
            if let content {
                RecipeListView(content.recipes, selection: $detail)
                    .toolbar {
                        ToolbarItem {
                            EditTagButton<T>()
                        }
                    }
                    .navigationTitle(content.value)
                    .environment(content)
            }
        } detail: {
            if let detail {
                RecipeView()
                    .toolbar {
                        ToolbarItem(placement: .destructiveAction) {
                            DeleteRecipeButton()
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            EditRecipeButton()
                        }
                    }
                    .navigationTitle(detail.name)
                    .environment(detail)
            }
        }
        .onTabSelected {
            let tab: Tab? = {
                switch T.self {
                case is Ingredient.Type:
                        .ingredient                   
                case is Category.Type:
                        .category
                default:
                    nil
                }
            }()
            guard $0 == tab,
                  $1 == tab else {
                return
            }
            content = nil
            detail = nil
        }
    }
}

#Preview {
    ModelContainerPreview { _ in
        TagNavigationView<Category>()
    }
}
