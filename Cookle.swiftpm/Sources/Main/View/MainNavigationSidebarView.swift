//
//  MainNavigationSidebarView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/28.
//

import SwiftUI

struct MainNavigationSidebarView: View {
    @Binding private var selection: MainNavigationSidebar?

    @AppStorage(.isSubscribeOn) private var isSubscribeOn

    @State private var isSettingsPresented = false

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
