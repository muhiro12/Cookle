//
//  DebugNavigationView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import SwiftData
import SwiftUI

struct DebugNavigationView: View {
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
        NavigationSplitView(columnVisibility: .constant(.all)) {
            DebugSidebarView(selection: $content)
        } content: {
            switch content {
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
            case .preview:
                DebugPreviewsView()
            case .none:
                EmptyView()
            }
        } detail: {
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
            }
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    DebugNavigationView()
}
