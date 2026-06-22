//
//  DebugNavigationView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import MHPlatform
import SwiftData
import SwiftUI

struct DebugNavigationView: View {
    @Environment(CookleAppLogging.self)
    private var logging

    @State private var content: DebugContent?
    @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar
    @State private var hasAppliedInitialCompactColumn = false

    @State private var diary: Diary?
    @State private var diaryObject: DiaryObject?
    @State private var recipe: Recipe?
    @State private var ingredient: Ingredient?
    @State private var ingredientObject: IngredientObject?
    @State private var category: Category?
    @State private var photo: Photo?
    @State private var photoObject: PhotoObject?

    var body: some View {
        NavigationSplitView(
            columnVisibility: .constant(.all),
            preferredCompactColumn: $preferredCompactColumn
        ) {
            DebugSidebarView(selection: $content)
        } content: {
            contentView(for: content)
        } detail: {
            detailView()
        }
        .task {
            applyInitialCompactColumnIfNeeded()
        }
        .onChange(of: content) {
            clearDetailSelections()
            syncPreferredCompactColumn()
        }
        .onChange(of: hasDetailSelection) {
            syncPreferredCompactColumn()
        }
    }
}

private extension DebugNavigationView {
    var modelContent: DebugContent? {
        switch content {
        case .diary,
             .diaryObject,
             .recipe,
             .photo,
             .photoObject,
             .ingredient,
             .ingredientObject,
             .category:
            content
        case .logs,
             .preview,
             .none:
            nil
        }
    }

    var hasDetailSelection: Bool {
        diary != nil ||
            diaryObject != nil ||
            recipe != nil ||
            ingredient != nil ||
            ingredientObject != nil ||
            category != nil ||
            photo != nil ||
            photoObject != nil
    }

    @ViewBuilder
    func detailView() -> some View {
        if let diary {
            DebugDetailView<Diary>()
                .environment(diary)
        } else if let diaryObject {
            DebugDetailView<DiaryObject>()
                .environment(diaryObject)
        } else if let recipe {
            DebugDetailView<Recipe>()
                .environment(recipe)
        } else if let photo {
            DebugDetailView<Photo>()
                .environment(photo)
        } else if let photoObject {
            DebugDetailView<PhotoObject>()
                .environment(photoObject)
        } else if let ingredient {
            DebugDetailView<Ingredient>()
                .environment(ingredient)
        } else if let ingredientObject {
            DebugDetailView<IngredientObject>()
                .environment(ingredientObject)
        } else if let category {
            DebugDetailView<Category>()
                .environment(category)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    func contentView(
        for content: DebugContent?
    ) -> some View {
        if let modelContent {
            modelContentView(
                for: modelContent
            )
        } else {
            switch content {
            case .logs:
                MHLogConsoleView(logging: logging.bootstrap)
            case .preview:
                DebugPreviewsView()
            case .none:
                EmptyView()
            case .some:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    func modelContentView(
        for content: DebugContent
    ) -> some View {
        switch content {
        case .logs,
             .preview:
            EmptyView()
        case .diary:
            DebugContentView(selection: $diary)
        case .diaryObject:
            DebugContentView(selection: $diaryObject)
        case .recipe:
            DebugContentView(selection: $recipe)
        case .photo:
            DebugContentView(selection: $photo)
        case .photoObject:
            DebugContentView(selection: $photoObject)
        case .ingredient:
            DebugContentView(selection: $ingredient)
        case .ingredientObject:
            DebugContentView(selection: $ingredientObject)
        case .category:
            DebugContentView(selection: $category)
        }
    }

    func clearDetailSelections() {
        diary = nil
        diaryObject = nil
        recipe = nil
        ingredient = nil
        ingredientObject = nil
        category = nil
        photo = nil
        photoObject = nil
    }

    func applyInitialCompactColumnIfNeeded() {
        guard !hasAppliedInitialCompactColumn else {
            return
        }

        hasAppliedInitialCompactColumn = true
        syncPreferredCompactColumn()
    }

    func syncPreferredCompactColumn() {
        preferredCompactColumn = CompactSplitColumnPolicy.threeColumn(
            hasContentSelection: content != nil,
            hasDetailSelection: hasDetailSelection
        )
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    DebugNavigationView()
}
