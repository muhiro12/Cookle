//
//  TagNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/13/24.
//

import SwiftUI

struct TagNavigationView<T: Tag>: View {
    @State private var tag: T?
    @State private var recipe: Recipe?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            TagListView<T>(selection: $tag)
        } content: {
            if let tag {
                TagView<T>(selection: $recipe)
                    .environment(tag)
            }
        } detail: {
            if let recipe {
                RecipeView()
                    .environment(recipe)
            }
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    TagNavigationView<Ingredient>()
}
