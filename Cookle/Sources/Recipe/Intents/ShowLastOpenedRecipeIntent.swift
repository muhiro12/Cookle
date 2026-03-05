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
    private enum Layout {
        static let imageHeight = CGFloat(Int("240") ?? .zero)
        static let imageCornerRadius = CGFloat(Int("8") ?? .zero)
    }

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
                        .frame(height: Layout.imageHeight)
                        .frame(maxWidth: .infinity)
                        .clipShape(.rect(cornerRadius: Layout.imageCornerRadius))
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
