//
//  RecipeCategoriesSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftData
import SwiftUI

struct RecipeCategoriesSection: View {
    @Environment(Recipe.self)
    private var recipe
    @Environment(\.openCookleRoute)
    private var openCookleRoute

    var body: some View {
        if let categories = recipe.categories,
           !categories.isEmpty {
            Section {
                ForEach(categories) { category in
                    Button {
                        openCategory(category)
                    } label: {
                        Text(category.value)
                            .cookleButtonRowContent()
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Categories")
            }
        }
    }
}

private extension RecipeCategoriesSection {
    func openCategory(_ category: Category) {
        openCookleRoute(
            .tagDetail(
                kind: .category,
                id: PersistentModelStableIdentifierCodec.stableIdentifier(
                    for: category
                )
            )
        )
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    List {
        RecipeCategoriesSection()
            .environment(recipes[0])
    }
}
