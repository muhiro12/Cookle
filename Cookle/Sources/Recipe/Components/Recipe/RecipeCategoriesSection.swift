//
//  RecipeCategoriesSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftData
import SwiftUI

struct RecipeCategoriesSection: View {
    @Environment(Recipe.self) private var recipe
    @Environment(\.modelContext) private var context

    var body: some View {
        if let categories = recipe.categories,
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

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    List {
        RecipeCategoriesSection()
            .environment(recipes[0])
    }
}
