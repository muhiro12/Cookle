//
//  DiaryNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/13/24.
//

import SwiftUI
import SwiftUtilities

struct DiaryNavigationView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var diary: Diary?
    @State private var recipe: Recipe?

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

#Preview {
    CooklePreview { _ in
        DiaryNavigationView()
    }
}
