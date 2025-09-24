//
//  ShowLastOpenedRecipeIntent.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/16.
//

import AppIntents
import SwiftData
import SwiftUI

struct ShowLastOpenedRecipeIntent: AppIntent {
    static var title: LocalizedStringResource {
        .init("Show Last Opened Recipe")
    }

    @Dependency private var modelContainer: ModelContainer

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let recipe = try RecipeService.lastOpenedRecipe(
            context: modelContainer.mainContext
        ) else {
            return .result(dialog: "Not Found")
        }
        return .result(dialog: .init(stringLiteral: recipe.name)) {
            VStack(alignment: .leading) {
                if let photo = recipe.photoObjects?.min()?.photo,
                   let image = UIImage(data: photo.data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 240)
                        .frame(maxWidth: .infinity)
                        .clipShape(.rect(cornerRadius: 8))
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
