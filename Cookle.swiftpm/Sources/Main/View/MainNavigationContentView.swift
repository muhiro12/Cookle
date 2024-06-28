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
                case .recipe:
                    RecipeListView(selection: $selection)
                case .ingredient:
                    TagListView<Ingredient>(selection: pathSelection())
                case .category:
                    TagListView<Category>(selection: pathSelection())
                case .photo:
                    PhotoListView()
                }
            }
            .navigationDestination(for: Diary.self) { diary in
                DiaryView(selection: $selection)
                    .environment(diary)
            }
            .navigationDestination(for: Ingredient.self) { ingredient in
                TagView<Ingredient>(selection: $selection)
                    .environment(ingredient)
            }
            .navigationDestination(for: Category.self) { category in
                TagView<Category>(selection: $selection)
                    .environment(category)
            }
            .navigationDestination(for: Photo.self) { photo in
                PhotoView(selection: $selection)
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
