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
            DebugNavigationSidebarView(selection: $content)
        } content: {
            switch content {
            case .diary:
                DebugNavigationContentView(selection: $diary)
            case .diaryObject:
                DebugNavigationContentView(selection: $diaryObject)
            case .recipe:
                DebugNavigationContentView(selection: $recipe)
            case .photo:
                DebugNavigationContentView(selection: $photo)
            case .photoObject:
                DebugNavigationContentView(selection: $photoObject)
            case .ingredient:
                DebugNavigationContentView(selection: $ingredient)
            case .ingredientObject:
                DebugNavigationContentView(selection: $ingredientObject)
            case .category:
                DebugNavigationContentView(selection: $category)
            case .none:
                EmptyView()
            }
        } detail: {
            if let diary {
                DebugNavigationDetailView<Diary>()
                    .environment(diary)
            } else if let diaryObject {
                DebugNavigationDetailView<DiaryObject>()
                    .environment(diaryObject)
            } else if let recipe {
                DebugNavigationDetailView<Recipe>()
                    .environment(recipe)
            } else if let photo {
                DebugNavigationDetailView<Photo>()
                    .environment(photo)
            } else if let photoObject {
                DebugNavigationDetailView<PhotoObject>()
                    .environment(photoObject)
            } else if let ingredient {
                DebugNavigationDetailView<Ingredient>()
                    .environment(ingredient)
            } else if let ingredientObject {
                DebugNavigationDetailView<IngredientObject>()
                    .environment(ingredientObject)
            } else if let category {
                DebugNavigationDetailView<Category>()
                    .environment(category)
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        DebugNavigationView()
    }
}
