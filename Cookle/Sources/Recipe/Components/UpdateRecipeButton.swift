//
//  UpdateRecipeButton.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/21/24.
//

import SwiftData
import SwiftUI

struct UpdateRecipeButton: View {
    @Environment(Recipe.self) private var recipe: Recipe
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    private let name: String
    private let photos: [PhotoData]
    private let servingSize: String
    private let cookingTime: String
    private let ingredients: [RecipeFormIngredient]
    private let steps: [String]
    private let categories: [String]
    private let note: String

    private let useShortTitle: Bool

    init(name: String,
         photos: [PhotoData],
         servingSize: String,
         cookingTime: String,
         ingredients: [RecipeFormIngredient],
         steps: [String],
         categories: [String],
         note: String,
         useShortTitle: Bool = false) {
        self.name = name
        self.photos = photos
        self.servingSize = servingSize
        self.cookingTime = cookingTime
        self.ingredients = ingredients
        self.steps = steps
        self.categories = categories
        self.note = note
        self.useShortTitle = useShortTitle
    }

    var body: some View {
        Button {
            do {
                let draft = try RecipeFormService.makeDraft(
                    name: name,
                    photos: photos,
                    servingSize: servingSize,
                    cookingTime: cookingTime,
                    ingredients: ingredients,
                    steps: steps,
                    categories: categories,
                    note: note
                )
                RecipeFormService.update(
                    context: context,
                    recipe: recipe,
                    draft: draft
                )
                CookleWidgetReloader.reloadRecipeWidgets()
                dismiss()
                if Int.random(in: 0..<5) == .zero {
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        requestReview()
                    }
                }
            } catch {
                assertionFailure(error.localizedDescription)
            }
        } label: {
            Label {
                if useShortTitle {
                    Text("Update")
                } else {
                    Text("Update \(recipe.name)")
                }
            } icon: {
                Image(systemName: "pencil")
            }
        }
        .disabled(
            (try? RecipeFormService.makeDraft(
                name: name,
                photos: photos,
                servingSize: servingSize,
                cookingTime: cookingTime,
                ingredients: ingredients,
                steps: steps,
                categories: categories,
                note: note
            )) == nil
        )
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    UpdateRecipeButton(
        name: .empty,
        photos: .empty,
        servingSize: .empty,
        cookingTime: .empty,
        ingredients: .empty,
        steps: .empty,
        categories: .empty,
        note: .empty
    )
    .environment(recipes[0])
}
