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
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    @Environment(CookleAppLogging.self)
    private var logging

    @State private var content: DebugContent?

    @State private var diary: Diary?
    @State private var diaryObject: DiaryObject?
    @State private var recipe: Recipe?
    @State private var ingredient: Ingredient?
    @State private var ingredientObject: IngredientObject?
    @State private var category: Category?
    @State private var photo: Photo?
    @State private var photoObject: PhotoObject?

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                NavigationSplitView(columnVisibility: .constant(.all)) {
                    DebugSidebarView(selection: $content)
                } content: {
                    regularContentView(for: content)
                } detail: {
                    regularDetailView()
                }
            } else {
                NavigationStack {
                    DebugSidebarView(selection: $content)
                        .listStyle(.insetGrouped)
                        .navigationDestination(isPresented: $content.isPresent()) {
                            compactContentView(for: content)
                        }
                }
            }
        }
        .onChange(of: content) {
            clearDetailSelections()
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

    @ViewBuilder
    func regularDetailView() -> some View {
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
    func regularContentView(
        for content: DebugContent?
    ) -> some View {
        if let modelContent {
            regularModelContentView(
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
    func regularModelContentView(
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

    @ViewBuilder
    func compactContentView(
        for content: DebugContent?
    ) -> some View {
        if let modelContent {
            compactModelContentView(
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
    func compactModelContentView(
        for content: DebugContent
    ) -> some View {
        switch content {
        case .logs,
             .preview:
            EmptyView()
        case .diary:
            compactModelContentView(selection: $diary)
        case .diaryObject:
            compactModelContentView(selection: $diaryObject)
        case .recipe:
            compactModelContentView(selection: $recipe)
        case .photo:
            compactModelContentView(selection: $photo)
        case .photoObject:
            compactModelContentView(selection: $photoObject)
        case .ingredient:
            compactModelContentView(selection: $ingredient)
        case .ingredientObject:
            compactModelContentView(selection: $ingredientObject)
        case .category:
            compactModelContentView(selection: $category)
        }
    }

    func compactModelContentView<Model: PersistentModel>(
        selection: Binding<Model?>
    ) -> some View {
        DebugContentView(selection: selection)
            .navigationDestination(isPresented: selection.isPresent()) {
                if let model = selection.wrappedValue {
                    DebugDetailView<Model>()
                        .environment(model)
                }
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
}

#Preview(traits: .modifier(CookleSampleData())) {
    DebugNavigationView()
}
