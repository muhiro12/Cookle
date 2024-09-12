//
//  MainNavigationSidebarView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/28.
//

import SwiftUI

struct MainNavigationSidebarView: View {
    @AppStorage(.isSubscribeOn) private var isSubscribeOn
    @AppStorage(.isDebugOn) private var isDebugOn

    @Binding private var selection: MainNavigationSidebar?

    @State private var isSettingsPresented = false
    @State private var isDebugPresented = false

    init(selection: Binding<MainNavigationSidebar?>) {
        self._selection = selection
    }

    var body: some View {
        List(selection: $selection) {
            Section {
                Label {
                    Text("Diary")
                } icon: {
                    Image(systemName: "book")
                }
                .tag(MainNavigationSidebar.diary)
            }
            Section {
                Label {
                    Text("Recipe")
                } icon: {
                    Image(systemName: "book.pages")
                }
                .tag(MainNavigationSidebar.recipe)
            }
            Section {
                Label {
                    Text("Ingredient")
                } icon: {
                    Image(systemName: "refrigerator")
                }
                .tag(MainNavigationSidebar.ingredient)
                Label {
                    Text("Category")
                } icon: {
                    Image(systemName: "frying.pan")
                }
                .tag(MainNavigationSidebar.category)
            }
            Section {
                Label {
                    Text("Photo")
                } icon: {
                    Image(systemName: "photo.stack")
                }
                .tag(MainNavigationSidebar.photo)
            }
            if !isSubscribeOn {
                AdvertisementSection(.small)
            }
        }
        .navigationTitle(Text("Cookle"))
        .toolbar {
            if isDebugOn {
                ToolbarItem {
                    Button("Debug", systemImage: "flask") {
                        isDebugPresented = true
                    }
                }
            }
            ToolbarItem {
                Button("Settings", systemImage: "gear") {
                    isSettingsPresented = true
                }
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsNavigationView()
        }
        .fullScreenCover(isPresented: $isDebugPresented) {
            DebugNavigationView()
        }
    }
}

#Preview {
    CooklePreview { _ in
        NavigationStack {
            MainNavigationSidebarView(selection: .constant(nil))
        }
    }
}
