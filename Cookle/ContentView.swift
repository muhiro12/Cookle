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
            DiaryView()
                .tabItem {
                    Label("Diary", systemImage: "book")
                }
            TagView()
                .tabItem {
                    Label("Tag", systemImage: "tag")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.modelContainer)
        .environment(PreviewData.tagStore)
}
