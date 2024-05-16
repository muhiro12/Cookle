//
//  DiaryNavigationView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import SwiftUI
import SwiftData

struct DiaryNavigationView: View {
    @Environment(\.modelContext) private var context

    @Query(Diary.descriptor) private var diaries: [Diary]

    @State private var content: Diary.ID?
    @State private var detail: Recipe?
    @State private var isPresented = false

    var body: some View {
        NavigationSplitView {
            DiaryListView(diaries, selection: $content)
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
            DiaryFormNavigationView()
        }
    }
}

#Preview {
    ModelContainerPreview { _ in
        DiaryNavigationView()
    }
}
