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
            DiaryRootView()
                .tabItem {
                    Label("Diary", systemImage: "book")
                }
            TagRootView<Ingredient>()
                .tabItem {
                    Label("Ingredient", systemImage: "refrigerator")
                }
            TagRootView<Category>()
                .tabItem {
                    Label("Category", systemImage: "frying.pan")
                }
            DebugRootView()
                .tabItem {
                    Label("Debug", systemImage: "flask")
                }
        }
    }
}

#Preview {
    ContentView()
}
