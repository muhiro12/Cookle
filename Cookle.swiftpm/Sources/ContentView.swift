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
    
    private let sharedModelContainer: ModelContainer    

    public init() {
        do {
            sharedModelContainer = try .init(
                for: Recipe.self
            ) 
            sharedModelContainer.configurations = [
                .init(cloudKitDatabase: isICloudOn ? .automatic : .none)
            ]
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        #if DEBUG
        isDebugOn = true
        #endif
    }

    public var body: some View {
        TabView {
            DiaryNavigationView()
                .tabItem {
                    Label("Diary", systemImage: "book")
                }
            RecipeNavigationView()
                .tabItem {
                    Label("Recipe", systemImage: "book.pages")
                }
            TagNavigationView<Ingredient>()
                .tabItem {
                    Label("Ingredient", systemImage: "refrigerator")
                }
            TagNavigationView<Category>()
                .tabItem {
                    Label("Category", systemImage: "frying.pan")
                }
            if isDebugOn {
                DebugNavigationView()
                    .tabItem {
                        Label("Debug", systemImage: "flask")
                    }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

#Preview {
    ContentView()
}
