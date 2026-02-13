//
//  SearchNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftUI

struct SearchNavigationView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var recipe: Recipe?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            if horizontalSizeClass == .regular {
                SearchView(selection: $recipe)
            } else {
                SearchView(selection: $recipe)
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
