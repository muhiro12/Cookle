//
//  SearchNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftUI

struct SearchNavigationView: View {
    @State private var recipe: Recipe?

    @State private var searchText = ""

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SearchResultList(searchText: searchText, selection: $recipe)
                .navigationTitle(Text("Search"))
                .searchable(text: $searchText)
        } detail: {
            if let recipe {
                RecipeView()
                    .environment(recipe)
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        SearchNavigationView()
    }
}
