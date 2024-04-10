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

    var body: some View {
        NavigationSplitView {
            List(tagStore.tags.filter { $0.type == .category }, id: \.self, selection: $content) {
                Text($0.name)
            }
        } content: {
            if let content {
                List(recipes.filter { $0.tag == content.name }, id: \.self, selection: $detail) { recipe in
                    Text(recipe.name)
                }
            }
        } detail: {
            if let detail {
                RecipeView()
                    .environment(detail)
            }
        }
    }
}

#Preview {
    TagView()
        .environment({
            let tagStore = TagStore()
            tagStore.insert(.init(type: .name, name: "tagA"))
            tagStore.insert(.init(type: .name, name: "tagB"))
            return tagStore
        }())
}
