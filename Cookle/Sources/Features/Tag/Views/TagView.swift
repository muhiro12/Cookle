//
//  TagView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/15.
//

import MHUI
import SwiftData
import SwiftUI

struct TagView<T: Tag>: View {
    @Environment(T.self)
    private var tag

    @Binding private var tagSelection: T?
    @Binding private var recipe: Recipe?

    var body: some View {
        List {
            MHContainerContent {
                recipeSection
                datesSection
                actionSection
            }
        }
        .mhListChrome(.content)
        .navigationTitle(tag.value)
        .toolbar {
            ToolbarItem {
                EditTagButton<T>()
            }
        }
    }

    init(
        tagSelection: Binding<T?> = .constant(nil),
        recipeSelection: Binding<Recipe?> = .constant(nil)
    ) {
        _tagSelection = tagSelection
        _recipe = recipeSelection
    }
}

private extension TagView {
    var recipeSection: some View {
        Section {
            if (tag.recipes ?? []).isEmpty {
                Text("Not used in any recipe.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach((tag.recipes ?? [])) { rowRecipe in
                    Button {
                        $recipe.cookleSelectForNavigation(
                            rowRecipe
                        )
                    } label: {
                        RecipeLabel()
                            .labelStyle(.titleAndLargeIcon)
                            .environment(rowRecipe)
                            .cookleButtonRowContent()
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            MHSectionHeader("Recipes")
        }
    }

    var datesSection: some View {
        Section {
            LabeledContent("Created At") {
                Text(tag.createdTimestamp, format: .dateTime.year().month().day())
            }
            .mhKeyValueLayout(.vertical)
            LabeledContent("Updated At") {
                Text(tag.modifiedTimestamp, format: .dateTime.year().month().day())
            }
            .mhKeyValueLayout(.vertical)
        }
    }

    var actionSection: some View {
        Section {
            MergeDuplicateTagButton<T>()
            EditTagButton<T>()
            deleteSectionButton
        }
    }

    @ViewBuilder var deleteSectionButton: some View {
        if let category = tag as? Category {
            DeleteCategoryButton {
                tagSelection = nil
            }
            .environment(category)
        } else if let ingredient = tag as? Ingredient {
            DeleteIngredientButton {
                tagSelection = nil
            }
            .environment(ingredient)
            if !(ingredient.recipes ?? []).isEmpty {
                Text(
                    IngredientDeleteCopy.inUseMessage(
                        value: ingredient.value,
                        recipeCount: (ingredient.recipes ?? []).count
                    )
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var ingredients: [Ingredient]
    NavigationStack {
        TagView<Ingredient>()
            .environment(ingredients[0])
    }
}
