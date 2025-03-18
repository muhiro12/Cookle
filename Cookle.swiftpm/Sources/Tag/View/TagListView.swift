//
//  TagListView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/10.
//

import SwiftData
import SwiftUI
import SwiftUtilities

struct TagListView<T: Tag>: View {
    @Environment(\.isPresented) private var isPresented

    @Query(T.descriptor(.all)) private var tags: [T]

    @Binding private var tag: T?

    @State private var searchText = ""

    init(selection: Binding<T?> = .constant(nil)) {
        _tag = selection
    }

    var body: some View {
        Group {
            if tags.isNotEmpty {
                List(tags, selection: $tag) { tag in
                    NavigationLink(value: tag) {
                        Text(tag.value)
                    }
                    .hidden(
                        searchText.isNotEmpty
                            && !tag.value.normalizedContains(searchText)
                            || tag.recipes.orEmpty.isEmpty
                    )
                }
                .searchable(text: $searchText)
            } else {
                AddRecipeButton()
            }
        }
        .navigationTitle(T.title)
        .toolbar {
            ToolbarItem {
                AddRecipeButton()
            }
            ToolbarItem {
                CloseButton()
                    .hidden(!isPresented)
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        NavigationStack {
            TagListView<Category>()
        }
    }
}
