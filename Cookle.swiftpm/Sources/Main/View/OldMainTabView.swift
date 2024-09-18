//
//  OldMainTabView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/28.
//

import SwiftUI

struct OldMainTabView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @AppStorage(.isDebugOn) private var isDebugOn

    @State private var selection = MainTab.diary

    var body: some View {
        TabView(selection: $selection) {
            DiaryNavigationView()
                .tag(MainTab.diary)
                .tabItem {
                    MainTab.diary.label
                }
            RecipeNavigationView()
                .tag(MainTab.recipe)
                .tabItem {
                    MainTab.recipe.label
                }
            PhotoNavigationView()
                .tag(MainTab.photo)
                .tabItem {
                    MainTab.photo.label
                }
            if horizontalSizeClass == .regular {
                TagNavigationView<Ingredient>()
                    .tag(MainTab.ingredient)
                    .tabItem {
                        MainTab.ingredient.label
                    }
                TagNavigationView<Category>()
                    .tag(MainTab.category)
                    .tabItem {
                        MainTab.category.label
                    }
            }
            if horizontalSizeClass == .regular {
                SettingsNavigationView()
                    .tag(MainTab.settings)
                    .tabItem {
                        MainTab.settings.label
                    }
                if isDebugOn {
                    DebugNavigationView()
                        .tag(MainTab.debug)
                        .tabItem {
                            MainTab.debug.label
                        }
                }
            }
            SearchNavigationView()
                .tag(MainTab.search)
                .tabItem {
                    MainTab.search.label
                }
        }
    }
}

#Preview {
    CooklePreview { _ in
        OldMainTabView()
    }
}
