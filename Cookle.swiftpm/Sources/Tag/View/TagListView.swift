//
//  TagListView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/10.
//

import SwiftData
import SwiftUI

struct TagListView<T: Tag>: View {
    @Query(T.descriptor) private var tags: [T]

    @Binding private var selection: CookleSelectionValue?

    @State private var searchText = ""

    init(selection: Binding<CookleSelectionValue?> = .constant(nil)) {
        _selection = selection
    }

    var body: some View {
        List(tags, id: \.self, selection: $selection) { tag in
            if tag.recipes.orEmpty.isNotEmpty {
                if tag.value.lowercased().contains(searchText.lowercased())
                    || searchText.isEmpty {
                    NavigationLink(selection: tag.selectionValue) {
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
