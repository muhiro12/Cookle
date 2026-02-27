//
//  SearchNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftUI

struct SearchNavigationView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding private var recipe: Recipe?
    @Binding private var incomingSearchQuery: String?

    init(
        selection: Binding<Recipe?> = .constant(nil),
        incomingSearchQuery: Binding<String?> = .constant(nil)
    ) {
        _recipe = selection
        _incomingSearchQuery = incomingSearchQuery
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            if horizontalSizeClass == .regular {
                SearchView(
                    selection: $recipe,
                    incomingSearchQuery: $incomingSearchQuery
                )
            } else {
                SearchView(
                    selection: $recipe,
                    incomingSearchQuery: $incomingSearchQuery
                )
                .listStyle(.insetGrouped)
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
    SearchNavigationView()
}
