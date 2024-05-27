//
//  DiaryNavigationView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import SwiftUI

struct DiaryNavigationView: View {
    @State private var content: Diary?
    @State private var detail: Recipe?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            DiaryListView(selection: $content)
                .toolbar {
                    ToolbarItem {
                        AddDiaryButton()
                    }
                    ToolbarItem {
                        AddRecipeButton()
                    }
                }
                .navigationTitle("Diary")
        } content: {
            if let content {
                DiaryView(selection: $detail)
                    .toolbar {
                        ToolbarItem(placement: .destructiveAction) {
                            DeleteDiaryButton()
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            EditDiaryButton()
                        }
                    }
                    .navigationTitle(content.date.formatted(.dateTime.year().month().day()))
                    .environment(content)
            }
        } detail: {
            if let detail {
                RecipeView()
                    .toolbar {
                        ToolbarItem(placement: .destructiveAction) {
                            DeleteRecipeButton()
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            EditRecipeButton()
                        }
                    }
                    .navigationTitle(detail.name)
                    .environment(detail)
            }
        }
        .onTabSelected {
            guard $0 == .diary,
                  $1 == .diary else {
                return
            }
            content = nil
            detail = nil
        }
    }
}

#Preview {
    ModelContainerPreview { _ in
        DiaryNavigationView()
            .environment(TabController(initialTab: .diary))
    }
}
