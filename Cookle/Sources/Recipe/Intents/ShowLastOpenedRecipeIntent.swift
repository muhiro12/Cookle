//
//  ShowLastOpenedRecipeIntent.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/16.
//

import AppIntents
import SwiftData
import SwiftUI
import SwiftUtilities

struct ShowLastOpenedRecipeIntent: AppIntent, IntentPerformer {
    typealias Input = (context: ModelContext, id: PersistentIdentifier?)
    typealias Output = RecipeEntity?

    @Dependency private var modelContainer: ModelContainer

    nonisolated static var title: LocalizedStringResource {
        .init("Show Last Opened Recipe")
    }

    private static func recipe(_ input: Input) throws -> Recipe? {
        guard let id = input.id else {
            return nil
        }
        return try input.context.fetchFirst(.recipes(.idIs(id)))
    }

    static func perform(_ input: Input) throws -> Output {
        guard let recipe = try recipe(input) else {
            return nil
        }
        return RecipeEntity(recipe)
    }

    @MainActor func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let lastOpenedRecipeID = AppStorage(.lastOpenedRecipeID).wrappedValue,
              let recipe = try Self.recipe(
                (context: modelContainer.mainContext, id: .init(base64Encoded: lastOpenedRecipeID))
              ) else {
            return .result(dialog: "Not Found")
        }
        return .result(dialog: .init(stringLiteral: recipe.name)) {
            CookleIntents.cookleView {
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
            }
        }
    }
}
