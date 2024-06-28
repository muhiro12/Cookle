//
//  MainNavigationSidebarView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/28.
//

import SwiftUI

struct MainNavigationSidebarView: View {
    @Binding private var selection: MainNavigationSidebar?

    @State private var isSettingsPresented = false

    init(selection: Binding<MainNavigationSidebar?>) {
        self._selection = selection
    }

    var body: some View {
        List(selection: $selection) {
            Section {
                Label("Diary", systemImage: "book")
                    .tag(MainNavigationSidebar.diary)
            }
            Section {
                Label("Recipe", systemImage: "book.pages")
                    .tag(MainNavigationSidebar.recipe)
            }
            Section {
                Label("Ingredient", systemImage: "refrigerator")
                    .tag(MainNavigationSidebar.ingredient)
                Label("Category", systemImage: "frying.pan")
                    .tag(MainNavigationSidebar.category)
            }
            Section {
                Label("Photo", systemImage: "photo.stack")
                    .tag(MainNavigationSidebar.photo)
            }
            Section {
                Advertisement(.small)
            }
        }
        .navigationTitle("Cookle")
        .toolbar {
            ToolbarItem {
                Button("Settings", systemImage: "gear") {
                    isSettingsPresented = true
                }
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsNavigationView()
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
