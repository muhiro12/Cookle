//
//  MainTabView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/28.
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @AppStorage(.isDebugOn) private var isDebugOn

    @State private var selection = MainTab.diary

    var body: some View {
        TabView(selection: $selection) {
            DiaryNavigationView()
                .tag(MainTab.diary)
                .tabItem {
                    Label {
                        Text("Diary")
                    } icon: {
                        Image(systemName: "book")
                    }
                }
            RecipeNavigationView()
                .tag(MainTab.recipe)
                .tabItem {
                    Label {
                        Text("Recipe")
                    } icon: {
                        Image(systemName: "book.pages")
                    }
                }
            PhotoNavigationView()
                .tag(MainTab.photo)
                .tabItem {
                    Label {
                        Text("Photo")
                    } icon: {
                        Image(systemName: "photo.stack")
                    }
                }
            if horizontalSizeClass == .regular {
                TagNavigationView<Ingredient>()
                    .tag(MainTab.ingredient)
                    .tabItem {
                        Label {
                            Text("Ingredient")
                        } icon: {
                            Image(systemName: "refrigerator")
                        }
                    }
                TagNavigationView<Category>()
                    .tag(MainTab.category)
                    .tabItem {
                        Label {
                            Text("Category")
                        } icon: {
                            Image(systemName: "frying.pan")
                        }
                    }
            }
            SearchNavigationView()
                .tag(MainTab.search)
                .tabItem {
                    Label {
                        Text("Search")
                    } icon: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            if horizontalSizeClass == .regular {
                SettingsNavigationView()
                    .tag(MainTab.settings)
                    .tabItem {
                        Label {
                            Text("Settings")
                        } icon: {
                            Image(systemName: "gear")
                        }
                    }
                if isDebugOn {
                    DebugNavigationView()
                        .tag(MainTab.debug)
                        .tabItem {
                            Label {
                                Text("Debug")
                            } icon: {
                                Image(systemName: "flask")
                            }
                        }
                }
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        MainTabView()
    }
}
