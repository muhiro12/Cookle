//
//  DiaryRootView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import SwiftUI
import SwiftData

struct DiaryRootView: View {
    @Environment(\.modelContext) private var context

    @Query private var diaries: [Diary]

    @State private var content: Diary.ID?
    @State private var detail: Recipe?
    @State private var isPresented = false

    var body: some View {
        NavigationSplitView {
            List(
                Array(
                    Dictionary(
                        grouping: diaries,
                        by: { $0.date.formatted(.iso8601.year().month()) }
                    )
                    .sorted {
                        $0.key > $1.key
                    }
                ),
                id: \.key,
                selection: $content
            ) { section in
                Section(section.key) {
                    ForEach(section.value) { diary in
                        Text(diary.date.formatted(.dateTime.month().day()))
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button("Add Diary", systemImage: "book") {
                        isPresented = true
                    }
                }
                ToolbarItem {
                    AddRecipeButton()
                }
            }
            .navigationTitle("Diary")
        } content: {
            if let content,
               let diary = diaries.first(where: { $0.id == content }) {
                DiaryView(selection: $detail)
                    .toolbar {
                        ToolbarItem {
                            AddRecipeButton()
                        }
                    }
                    .navigationTitle(diary.date.formatted(.dateTime.year().month().day()))
                    .environment(diary)
            }
        } detail: {
            if let detail {
                RecipeView()
                    .toolbar {
                        ToolbarItem {
                            EditRecipeButton()
                        }
                    }
                    .navigationTitle(detail.name)
                    .environment(detail)
            }
        }
        .sheet(isPresented: $isPresented) {
            DiaryFormRootView()
        }
    }
}

#Preview {
    ModelContainerPreview { _ in
        DiaryRootView()
    }
}
