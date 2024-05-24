//
//  ContentView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import SwiftUI
import SwiftData

public struct ContentView: View {
    @AppStorage(.isICloudOn) private var isICloudOn
    @AppStorage(.isDebugOn) private var isDebugOn

    private let sharedTabController: TabController
    private let sharedModelContainer: ModelContainer

    public init() {
        sharedTabController = .init(initialTab: .diary)

        sharedModelContainer = try! .init(for: Recipe.self)
        sharedModelContainer.configurations = [
            .init(cloudKitDatabase: isICloudOn ? .automatic : .none)
        ]
        
        #if DEBUG
        isDebugOn = true
        #endif
    }

    public var body: some View {
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
        .modelContainer(sharedModelContainer)
    }
}

#Preview {
    ContentView()
}
