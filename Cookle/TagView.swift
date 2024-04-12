//
//  TagView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import SwiftUI
import SwiftData

struct TagView: View {
    @Environment(TagStore.self) private var tagStore

    @Query private var recipes: [Recipe]

    @State private var content: Tag?
    @State private var detail: Recipe?
    @State private var isListStyle = false

    var body: some View {
        NavigationSplitView {
            VStack {
                ScrollView {
                    LazyVGrid(columns: (0..<3).map { _ in .init() }) {
                        ForEach(tagStore.tags.filter { $0.type == .custom }) { tag in
                            Button(tag.value) {
                                content = tag
                            }
                        }
                        .padding()
                    }
                }
                List(selection: $content) {}
                    .frame(height: .zero)
            }
            .navigationTitle("Tag")
        } content: {
            if let content {
                VStack {
                    if isListStyle {
                        List(recipes.filter { $0.tagList.contains(content.value) }, id: \.self, selection: $detail) { recipe in
                            Text(recipe.name)
                        }
                    } else {
                        RecipeGridView(recipes.filter { $0.tagList.contains(content.value) },
                                       selection: $detail)
                    }
                    List(selection: $detail) {}
                        .frame(height: .zero)
                }
                .navigationTitle(content.value)
                .toolbar {
                    ToolbarItem {
                        Button("Toggle Style", systemImage: "list.bullet.rectangle") {
                            isListStyle.toggle()
                        }
                    }
                }
            }
        } detail: {
            if let detail {
                RecipeView()
                    .navigationTitle(detail.name)
                    .environment(detail)
            }
        }
    }
}

#Preview {
    TagView()
        .modelContainer(PreviewData.modelContainer)
        .environment(PreviewData.tagStore)
}
