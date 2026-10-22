//
//  RecipeNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/13/24.
//

import SwiftUI

struct RecipeNavigationView: View {
    private let showsAIShortcut: Bool

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Binding private var recipe: Recipe?
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar
    @State private var hasAppliedInitialCompactColumn = false

    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            preferredCompactColumn: $preferredCompactColumn
        ) {
            RecipeListView(selection: $recipe, showsAIShortcut: showsAIShortcut)
                .cookleSplitSidebar(isExpanded: horizontalSizeClass == .regular)
        } detail: {
            if let recipe {
                RecipeView()
                    .environment(recipe)
            } else {
                SplitContentPlaceholder("No Recipe Selected")
            }
        }
        .task {
            applyInitialCompactColumnIfNeeded()
        }
        .onChange(of: recipe?.persistentModelID) {
            syncPreferredCompactColumn()
        }
    }

    init(selection: Binding<Recipe?> = .constant(nil), showsAIShortcut: Bool = false) {
        _recipe = selection
        self.showsAIShortcut = showsAIShortcut
    }
}

private extension RecipeNavigationView {
    func applyInitialCompactColumnIfNeeded() {
        guard !hasAppliedInitialCompactColumn else {
            return
        }

        hasAppliedInitialCompactColumn = true
        syncPreferredCompactColumn()
    }

    func syncPreferredCompactColumn() {
        preferredCompactColumn = CompactSplitColumnPolicy.twoColumn(
            hasDetailSelection: recipe != nil
        )
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    RecipeNavigationView()
}
