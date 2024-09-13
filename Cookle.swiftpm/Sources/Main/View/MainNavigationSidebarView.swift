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

    @Binding private var content: CookleSelectionValue?

    @State private var isSettingsPresented = false
    @State private var isDebugPresented = false

    init(content: Binding<CookleSelectionValue?> = .constant(nil)) {
        _content = content
    }

    var body: some View {
        List(selection: $content) {
            Section {
                NavigationLink(selection: .mainNavigationSidebar(.diary)) {
                    Label {
                        Text("Diary")
                    } icon: {
                        Image(systemName: "book")
                    }
                }
            }
            Section {
                NavigationLink(selection: .mainNavigationSidebar(.recipe)) {
                    Label {
                        Text("Recipe")
                    } icon: {
                        Image(systemName: "book.pages")
                    }
                }
            }
            Section {
                NavigationLink(selection: .mainNavigationSidebar(.ingredient)) {
                    Label {
                        Text("Ingredient")
                    } icon: {
                        Image(systemName: "refrigerator")
                    }
                }
                NavigationLink(selection: .mainNavigationSidebar(.category)) {
                    Label {
                        Text("Category")
                    } icon: {
                        Image(systemName: "frying.pan")
                    }
                }
            }
            Section {
                NavigationLink(selection: .mainNavigationSidebar(.photo)) {
                    Label {
                        Text("Photo")
                    } icon: {
                        Image(systemName: "photo.stack")
                    }
                }
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
            MainNavigationSidebarView()
        }
    }
}
