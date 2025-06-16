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
    static var title: LocalizedStringResource {
        .init("Show Last Opened Recipe")
    }

    typealias Input = PersistentIdentifier?
    typealias Output = Recipe?

    @MainActor
    static func perform(_ input: Input) throws -> Output {
        guard let id = input else { return nil }
        return try CookleIntents.context.fetchFirst(.recipes(.idIs(id)))
    }

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let recipe = try Self.perform(AppStorage(.lastOpenedRecipeID).wrappedValue) else {
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
