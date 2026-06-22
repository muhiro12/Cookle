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
    @State private var isSearchPresented = false

    var body: some View {
        contentView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cookleTopLevelNavigationChrome(T.title)
            .searchable(
                text: $searchText,
                isPresented: $isSearchPresented,
                prompt: Text("Search")
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .toolbar {
                ToolbarItem {
                    AddRecipeButton()
                }
                ToolbarItem {
                    if isPresented {
                        CloseButton()
                    }
                }
            }
    }

    init(selection: Binding<T?> = .constant(nil)) {
        _tag = selection
    }
}

private extension TagListView {
    @ViewBuilder var contentView: some View {
        if !filteredTags.isEmpty {
            tagList
        } else {
            emptyStateView
        }
    }

    var tagList: some View {
        List(filteredTags) { rowTag in
            tagRow(for: rowTag)
        }
    }

    @ViewBuilder var emptyStateView: some View {
        if !tags.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
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
    }

    var filteredTags: [T] {
        tags.filter { tag in
            searchText.isEmpty
                || tag.value.normalizedContains(searchText)
        }
    }

    func usageText(for tag: T) -> String {
        let recipeCount = (tag.recipes ?? []).count
        let recipeLabel = recipeCount == 1 ? "recipe" : "recipes"
        let duplicateCount = TagOperations.duplicateTags(
            matching: tag,
            in: tags
        ).count

        if recipeCount == 0 {
            return duplicateUsageText(
                baseText: "Unused",
                duplicateCount: duplicateCount
            )
        }

        return duplicateUsageText(
            baseText: "Used by \(recipeCount) \(recipeLabel)",
            duplicateCount: duplicateCount
        )
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

    func duplicateUsageText(
        baseText: String,
        duplicateCount: Int
    ) -> String {
        guard duplicateCount > 1 else {
            return baseText
        }

        return "\(baseText) · \(duplicateCount) possible duplicates"
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        TagListView<Category>()
    }
}
