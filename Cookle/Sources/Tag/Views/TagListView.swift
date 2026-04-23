//
//  TagListView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/10.
//

import SwiftData
import SwiftUI

struct TagListView<T: Tag>: View {
    @Environment(\.isPresented)
    private var isPresented

    @Query(T.descriptor(.all))
    private var tags: [T]

    @Binding private var tag: T?

    @State private var searchText = ""

    var body: some View {
        contentView
            .cookleTopLevelNavigationChrome(T.title)
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

    init(selection: Binding<T?> = .constant(nil)) {
        _tag = selection
    }
}

private extension TagListView {
    @ViewBuilder var contentView: some View {
        if filteredTags.isNotEmpty {
            tagList
        } else {
            emptyStateView
        }
    }

    var tagList: some View {
        List(filteredTags) { rowTag in
            tagRow(for: rowTag)
        }
        .searchable(text: $searchText)
    }

    var emptyStateView: some View {
        ContentUnavailableView {
            Label {
                Text(T.title)
            } icon: {
                Image(systemName: "tag")
                    .accessibilityHidden(true)
            }
        } description: {
            Text("Tags appear after recipes create them.")
        } actions: {
            AddRecipeButton()
        }
    }

    var filteredTags: [T] {
        tags.filter { tag in
            searchText.isEmpty
                || tag.value.normalizedContains(searchText)
        }
    }

    func usageText(for tag: T) -> String {
        let recipeCount = tag.recipes.orEmpty.count
        let recipeLabel = recipeCount == 1 ? "recipe" : "recipes"

        if recipeCount == 0 {
            return "Unused"
        }

        return "Used by \(recipeCount) \(recipeLabel)"
    }

    func tagRow(for rowTag: T) -> some View {
        Button {
            $tag.cookleSelectForNavigation(
                rowTag
            )
        } label: {
            VStack(alignment: .leading) {
                Text(rowTag.value)
                Text(usageText(for: rowTag))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .cookleButtonRowContent()
        }
        .buttonStyle(.plain)
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        TagListView<Category>()
    }
}
