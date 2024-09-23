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
        List(tags, id: \.self, selection: $tag) { tag in
            if tag.recipes.isNotEmpty {
                if tag.value.normalizedContains(searchText)
                    || searchText.isEmpty {
                    NavigationLink(value: tag) {
                        Text(tag.value)
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle(T.title)
        .toolbar {
            ToolbarItem {
                AddRecipeButton()
            }
            if isPresented {
                ToolbarItem {
                    CloseButton()
                }
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
