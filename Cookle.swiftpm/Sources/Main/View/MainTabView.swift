//
//  MainTabView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/28.
//

import SwiftUI

struct MainTabView: View {
    @AppStorage(.isDebugOn) private var isDebugOn

    var body: some View {
        TabView {
            DiaryNavigationView()
                .tabItem {
                    Label {
                        Text("Diary")
                    } icon: {
                        Image(systemName: "book")
                    }
                }
            RecipeNavigationView()
                .tabItem {
                    Label {
                        Text("Recipe")
                    } icon: {
                        Image(systemName: "book.pages")
                    }
                }
            TagNavigationView<Ingredient>()
                .tabItem {
                    Label {
                        Text("Ingredient")
                    } icon: {
                        Image(systemName: "refrigerator")
                    }
                }
            TagNavigationView<Category>()
                .tabItem {
                    Label {
                        Text("Category")
                    } icon: {
                        Image(systemName: "frying.pan")
                    }
                }
            PhotoNavigationView()
                .tabItem {
                    Label {
                        Text("Photo")
                    } icon: {
                        Image(systemName: "photo.stack")
                    }
                }
            SettingsNavigationView()
                .tabItem {
                    Label {
                        Text("Settings")
                    } icon: {
                        Image(systemName: "gear")
                    }
                }
            if isDebugOn {
                DebugNavigationView()
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

#Preview {
    CooklePreview { _ in
        MainTabView()
    }
}
