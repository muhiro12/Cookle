//
//  ContentView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import SwiftUI
import SwiftData

public struct ContentView: View {
    private let sharedModelContainer: ModelContainer = {
        do {
            return try .init(for: Recipe.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    public init() {}

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
            DebugNavigationView()
                .tabItem {
                    Label("Debug", systemImage: "flask")
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

#Preview {
    ContentView()
}
