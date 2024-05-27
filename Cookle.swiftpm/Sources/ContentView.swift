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

    private var sharedModelContainer: ModelContainer!
    private var sharedTabController: TabController!

    public init() {
        sharedModelContainer = try! .init(
            for: Recipe.self,
            configurations: .init(
                cloudKitDatabase: isICloudOn ? .automatic : .none
            )
        )

        sharedTabController = .init(initialTab: .diary)

        // TODO: Remove
        isDebugOn = true
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
        .modelContainer(sharedModelContainer)
        .environment(sharedTabController)
    }
}

#Preview {
    ContentView()
}
