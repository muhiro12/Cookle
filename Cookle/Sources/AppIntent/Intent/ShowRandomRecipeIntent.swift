//
//  ShowRandomRecipeIntent.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/16.
//

import AppIntents
import SwiftUI
import SwiftUtilities

struct ShowRandomRecipeIntent: AppIntent, IntentPerformer {
    static var title: LocalizedStringResource {
        .init("Show Random Recipe")
    }

    typealias Input = Void
    typealias Output = RecipeEntity?

    @MainActor
    private static func recipe() throws -> Recipe? {
        try CookleIntents.context.fetchRandom(.recipes(.all))
    }

    @MainActor
    static func perform(_: Input) throws -> Output {
        guard let recipe = try recipe() else {
            return nil
        }
        return RecipeEntity(recipe)
    }

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let recipe = try Self.recipe() else {
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
