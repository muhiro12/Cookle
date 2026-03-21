//
//  SearchNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftUI

struct SearchNavigationView: View {
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Binding private var recipe: Recipe?
    @Binding private var incomingSearchQuery: String?

    var body: some View {
        if horizontalSizeClass == .regular {
            NavigationSplitView(columnVisibility: .constant(.all)) {
                SearchView(
                    selection: $recipe,
                    incomingSearchQuery: $incomingSearchQuery
                )
            } detail: {
                if let recipe {
                    RecipeView()
                        .environment(recipe)
                }
            }
        } else {
            NavigationStack {
                SearchView(
                    selection: $recipe,
                    incomingSearchQuery: $incomingSearchQuery
                )
                .navigationDestination(isPresented: $recipe.isPresent()) {
                    if let recipe {
                        RecipeView()
                            .environment(recipe)
                    }
                }
            }
        }
    }

    init(
        selection: Binding<Recipe?> = .constant(nil),
        incomingSearchQuery: Binding<String?> = .constant(nil)
    ) {
        _recipe = selection
        _incomingSearchQuery = incomingSearchQuery
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    SearchNavigationView()
}
