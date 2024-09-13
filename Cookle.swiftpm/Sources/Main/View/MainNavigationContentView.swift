//
//  MainNavigationContentView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/28.
//

import SwiftUI

struct MainNavigationContentView: View {
    @Binding private var detail: CookleSelectionValue?

    @State private var selection: CookleSelectionValue?

    private var content: MainNavigationSidebar

    init(_ content: MainNavigationSidebar, detail: Binding<CookleSelectionValue?> = .constant(nil)) {
        self.content = content
        self._detail = detail
    }

    var body: some View {
        NavigationStack {
            Group {
                switch content {
                case .diary:
                    DiaryListView(selection: $selection)
                case .recipe:
                    RecipeListView(selection: $detail)
                case .ingredient:
                    TagListView<Ingredient>(selection: $selection)
                case .category:
                    TagListView<Category>(selection: $selection)
                case .photo:
                    PhotoListView(selection: $selection)
                }
            }
            .navigationDestination(item: $selection) { selection in
                switch selection {
                case .diary(let diary):
                    DiaryView(selection: $detail)
                        .environment(diary)
                case .ingredient(let ingredient):
                    TagView<Ingredient>(selection: $detail)
                        .environment(ingredient)
                case .category(let category):
                    TagView<Category>(selection: $detail)
                        .environment(category)
                case .photo(let photo):
                    PhotoView(selection: $detail)
                        .environment(photo)
                default:
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        MainNavigationContentView(.diary)
    }
}
