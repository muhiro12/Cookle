//
//  ContentView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
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
    }
}

#Preview {
    ContentView()
}
