//
//  MainTabView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/27.
//

import SwiftUI

struct MainTabView: View {
    @AppStorage(.isDebugOn) private var isDebugOn

    private var sharedTabController = TabController(initialTab: .diary)

    var body: some View {
        TabView(selection: sharedTabController.selection) {
            DiaryNavigationView()
                .tabItem {
                    Label("Diary", systemImage: "book")
                }
                .tag(Tab.diary)
            RecipeNavigationView()
                .tabItem {
                    Label("Recipe", systemImage: "book.pages")
                }
                .tag(Tab.recipe)
            TagNavigationView<Ingredient>()
                .tabItem {
                    Label("Ingredient", systemImage: "refrigerator")
                }
                .tag(Tab.ingredient)
            TagNavigationView<Category>()
                .tabItem {
                    Label("Category", systemImage: "frying.pan")
                }
                .tag(Tab.category)
            if isDebugOn {
                DebugNavigationView()
                    .tabItem {
                        Label("Debug", systemImage: "flask")
                    }
                    .tag(Tab.debug)
            }
        }
        .environment(sharedTabController)
        .task {
            // TODO: Remove
            isDebugOn = true
        }
    }
}

#Preview {
    MainTabView()
}
