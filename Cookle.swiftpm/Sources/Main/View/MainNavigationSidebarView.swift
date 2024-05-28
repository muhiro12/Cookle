//
//  MainNavigationSidebarView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/28.
//

import SwiftUI

struct MainNavigationSidebarView: View {
    @AppStorage(.isDebugOn) private var isDebugOn

    @Binding private var selection: MainNavigationSidebar?

    @State private var isSettingsPresented = false

    init(selection: Binding<MainNavigationSidebar?>) {
        self._selection = selection
    }

    var body: some View {
        List(selection: $selection) {
            Label("Diary", systemImage: "book")
                .tag(MainNavigationSidebar.diary)
            Label("Recipe", systemImage: "book.pages")
                .tag(MainNavigationSidebar.recipe)
            Label("Ingredient", systemImage: "refrigerator")
                .tag(MainNavigationSidebar.ingredient)
            Label("Category", systemImage: "frying.pan")
                .tag(MainNavigationSidebar.category)
        }
        .toolbar {
            if isDebugOn {
                ToolbarItem {
                    Button("Settings", systemImage: "gear") {
                        isSettingsPresented = true
                    }
                }
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            DebugNavigationView()
        }
        .navigationTitle("Cookle")
    }
}

#Preview {
    MainNavigationSidebarView(selection: .constant(nil))
}
