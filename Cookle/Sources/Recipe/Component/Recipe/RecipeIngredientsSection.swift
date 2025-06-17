//
//  RecipeIngredientsSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI

struct RecipeIngredientsSection: View {
    @Environment(RecipeEntity.self) private var recipe
    @Environment(\.modelContext) private var context

    var body: some View {
        if let objects = try? recipe.model(context: context)?.ingredientObjects,
           objects.isNotEmpty {
            Section {
                ForEach(objects.sorted()) { object in
                    HStack {
                        Text(object.ingredient?.value ?? "")
                        Spacer()
                        Text(object.amount)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Ingredients")
            }
        }
    }
}

#Preview {
    List {
        CooklePreview { preview in
            RecipeIngredientsSection()
                .environment(RecipeEntity(preview.recipes[0])!)
        }
    }
}
