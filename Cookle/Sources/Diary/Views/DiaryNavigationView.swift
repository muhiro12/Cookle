//
//  DiaryNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/13/24.
//

import SwiftUI

struct DiaryNavigationView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding private var diary: Diary?
    @Binding private var recipe: Recipe?

    init(
        selection: Binding<Diary?> = .constant(nil),
        recipeSelection: Binding<Recipe?> = .constant(nil)
    ) {
        _diary = selection
        _recipe = recipeSelection
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            if horizontalSizeClass == .regular {
                DiaryListView(selection: $diary)
            } else {
                DiaryListView(selection: $diary)
                    .listStyle(.insetGrouped)
            }
        } content: {
            if let diary {
                DiaryView(selection: $recipe)
                    .environment(diary)
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
    DiaryNavigationView()
}
