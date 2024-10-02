//
//  SearchNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftUI

struct SearchNavigationView: View {
    @State private var recipe: Recipe?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SearchView(selection: $recipe)
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
