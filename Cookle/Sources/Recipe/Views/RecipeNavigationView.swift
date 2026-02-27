//
//  RecipeNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/13/24.
//

import SwiftUI

struct RecipeNavigationView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding private var recipe: Recipe?

    init(selection: Binding<Recipe?> = .constant(nil)) {
        _recipe = selection
    }

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

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    RecipeNavigationView()
}
