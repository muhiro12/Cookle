//
//  DebugNavigationView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import SwiftUI
import SwiftData

struct DebugNavigationView: View {
    @Environment(\.modelContext) private var context

    @State private var content: DebugContent?
    @State private var detail: Int?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            DebugRootView(selection: $content)
                .toolbar {
                    ToolbarItem {
                        Button("Delete All", systemImage: "trash") {
                            withAnimation {
                                try! context.delete(model: Diary.self)
                                try! context.delete(model: DiaryObject.self)
                                try! context.delete(model: Recipe.self)
                                try! context.delete(model: Ingredient.self)
                                try! context.delete(model: IngredientObject.self)
                                try! context.delete(model: Category.self)
                            }
                        }
                    }
                    ToolbarItem {
                        Button("Add Random Diary", systemImage: "dice") {
                            withAnimation {
                                _ = ModelContainerPreview { _ in
                                    EmptyView()
                                }.randomDiary(context)
                            }
                        }
                    }
                }
                .navigationTitle("Debug")
        } content: {
            if let content {
                DebugContentView(content, selection: $detail)
                    .navigationTitle("Content")
            }
        } detail: {
            if let detail,
               let content {
                DebugDetailView(detail, content: content)
                    .navigationTitle("Detail")
            }
        }
        .onTabSelected {
            guard $0 == .debug,
                  $1 == .debug else {
                return
            }
            content = nil
            detail = nil
        }
    }
}

#Preview {
    ModelContainerPreview { _ in
        DebugNavigationView()
    }
}
