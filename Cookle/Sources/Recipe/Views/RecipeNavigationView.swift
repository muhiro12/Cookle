//
//  RecipeNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/13/24.
//

import SwiftUI

struct RecipeNavigationView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var recipe: Recipe?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            if horizontalSizeClass == .regular {
                RecipeListView(selection: $recipe)
            } else {
                RecipeListView(selection: $recipe)
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

#Preview {
    CooklePreview { _ in
        RecipeNavigationView()
    }
}
