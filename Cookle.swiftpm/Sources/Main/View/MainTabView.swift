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
                Label {
                    Text("Diary")
                } icon: {
                    Image(systemName: "book")
                }
            }
            Tab(value: .recipe) {
                RecipeNavigationView()
            } label: {
                Label {
                    Text("Recipe")
                } icon: {
                    Image(systemName: "book.pages")
                }
            }
            Tab(value: .photo) {
                PhotoNavigationView()
            } label: {
                Label {
                    Text("Photo")
                } icon: {
                    Image(systemName: "photo.stack")
                }
            }
            if horizontalSizeClass == .regular {
                Tab(value: .ingredient) {
                    TagNavigationView<Ingredient>()
                } label: {
                    Label {
                        Text("Ingredient")
                    } icon: {
                        Image(systemName: "refrigerator")
                    }
                }
                Tab(value: .category) {
                    TagNavigationView<Category>()
                } label: {
                    Label {
                        Text("Category")
                    } icon: {
                        Image(systemName: "frying.pan")
                    }
                }
            }
            if horizontalSizeClass == .regular {
                Tab(value: .settings) {
                    SettingsNavigationView()
                } label: {
                    Label {
                        Text("Settings")
                    } icon: {
                        Image(systemName: "gear")
                    }
                }
                if isDebugOn {
                    Tab(value: .debug) {
                        DebugNavigationView()
                    } label: {
                        Label {
                            Text("Debug")
                        } icon: {
                            Image(systemName: "flask")
                        }
                    }
                }
            }
            Tab(value: .search, role: .search) {
                SearchNavigationView()
            } label: {
                Label {
                    Text("Search")
                } icon: {
                    Image(systemName: "magnifyingglass")
                }
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
