//
//  RecipeCategoriesSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI

struct RecipeCategoriesSection: View {
    @Environment(RecipeEntity.self) private var recipe
    @Environment(\.modelContext) private var context

    var body: some View {
        if let categories = try? recipe.model(context: context)?.categories,
           categories.isNotEmpty {
            Section {
                ForEach(categories) {
                    Text($0.value)
                }
            } header: {
                Text("Categories")
            }
        }
    }
}

#Preview {
    CooklePreview { preview in
        List {
            RecipeCategoriesSection()
                .environment(RecipeEntity(preview.recipes[0])!)
        }
    }
}
