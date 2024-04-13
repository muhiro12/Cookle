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
            DiaryView<YearMonthDay>()
                .tabItem {
                    Label("Diary", systemImage: "book")
                }
            TagView<Ingredient>()
                .tabItem {
                    Label("Ingredient", systemImage: "refrigerator")
                }
            TagView<Category>()
                .tabItem {
                    Label("Category", systemImage: "frying.pan")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.modelContainer)
        .environment(\.inMemoryContext, PreviewData.inMemoryContext)
}
