//
//  DiaryNavigationView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/13/24.
//

import SwiftUI
import SwiftUtilities

struct DiaryNavigationView: View {
    @State private var diary: Diary?
    @State private var recipe: Recipe?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            DiaryListView(selection: $diary)
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
