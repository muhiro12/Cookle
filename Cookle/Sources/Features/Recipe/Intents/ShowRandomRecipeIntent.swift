//
//  ShowRandomRecipeIntent.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/16.
//

import AppIntents
import SwiftData
import SwiftUI

struct ShowRandomRecipeIntent: AppIntent {
    static var title: LocalizedStringResource {
        .init("Show Random Recipe")
    }

    @Dependency private var modelContainer: ModelContainer

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let recipe = try RecipeOperations.randomRecipe(
            context: modelContainer.mainContext
        ) else {
            return .result(dialog: "Not Found")
        }
        return .result(dialog: .init(stringLiteral: recipe.name)) {
            VStack(alignment: .leading) {
                if let photo = recipe.primaryPhoto,
                   let image = UIImage(data: photo.data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: RecipePreviewLayout.imageHeight)
                        .frame(maxWidth: .infinity)
                        .clipShape(.rect(cornerRadius: RecipePreviewLayout.imageCornerRadius))
                }
                RecipeIngredientsSection()
                Divider()
                RecipeStepsSection()
            }
            .environment(recipe)
            .safeAreaPadding()
            .modelContainer(modelContainer)
        }
    }
}
