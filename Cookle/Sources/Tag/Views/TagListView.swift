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
        Group {
            if filteredTags.isNotEmpty {
                List(filteredTags) { tag in
                    Button {
                        self.tag = tag
                    } label: {
                        VStack(alignment: .leading) {
                            Text(tag.value)
                            Text(usageText(for: tag))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .cookleButtonRowContent()
                    }
                    .buttonStyle(.plain)
                }
                .searchable(text: $searchText)
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
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        TagListView<Category>()
    }
}
