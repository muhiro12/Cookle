//
//  MainTabView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftUI

@available(iOS 18.0, *)
struct MainTabView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @AppStorage(.isDebugOn) private var isDebugOn

    @State private var selection = MainTab.diary

    var body: some View {
        TabView(selection: $selection) {
            Tab(value: .diary) {
                DiaryNavigationView()
            } label: {
                MainTab.diary.label
            }
            Tab(value: .recipe) {
                RecipeNavigationView()
            } label: {
                MainTab.recipe.label
            }
            Tab(value: .photo) {
                PhotoNavigationView()
            } label: {
                MainTab.photo.label
            }
            if horizontalSizeClass == .regular {
                Tab(value: .ingredient) {
                    TagNavigationView<Ingredient>()
                } label: {
                    MainTab.ingredient.label
                }
                Tab(value: .category) {
                    TagNavigationView<Category>()
                } label: {
                    MainTab.category.label
                }
                Tab(value: .settings) {
                    SettingsNavigationView()
                } label: {
                    MainTab.settings.label
                }
                if isDebugOn {
                    Tab(value: .debug) {
                        DebugNavigationView()
                    } label: {
                        MainTab.debug.label
                    }
                }
            } else {
                Tab(value: .menu) {
                    MenuNavigationView()
                } label: {
                    MainTab.menu.label
                }
            }
            Tab(value: .search, role: .search) {
                SearchNavigationView()
            } label: {
                MainTab.search.label
            }
        }
    }
}

@available(iOS 18.0, *)
#Preview {
    CooklePreview { _ in
        MainTabView()
    }
}
