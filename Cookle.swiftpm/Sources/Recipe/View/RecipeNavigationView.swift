//
//  RecipeNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/13/24.
//

import SwiftUI

struct RecipeNavigationView: View {
    @State private var recipe: Recipe?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            RecipeListView(selection: $recipe)
        } detail: {
            if let recipe {
                RecipeView()
                    .environment(recipe)
            }
        }
    }
}
