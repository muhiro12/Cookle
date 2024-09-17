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
        if #available(iOS 18.0, *) {
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
            }
        } else {
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
                PhotoNavigationView()
                    .tabItem {
                        Label {
                            Text("Photo")
                        } icon: {
                            Image(systemName: "photo.stack")
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
                if horizontalSizeClass == .regular {
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
    }
}

#Preview {
    CooklePreview { _ in
        MainTabView()
    }
}
