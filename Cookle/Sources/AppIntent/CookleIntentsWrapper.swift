//
//  CookleIntents.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/8/24.
//

import AppIntents
import SwiftData
import SwiftUI

@MainActor
enum CookleIntents {}

extension CookleIntents {
    static func performOpenCookle() throws -> some IntentResult {
        .result()
    }

    static func performShowSearchResult(searchText: String) throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        var recipes = try context.fetch(
            .recipes(.nameContains(searchText))
        )
        let ingredients = try context.fetch(
            searchText.count < 3
                ? .ingredients(.valueIs(searchText))
                : .ingredients(.valueContains(searchText))
        )
        let categories = try context.fetch(
            searchText.count < 3
                ? .categories(.valueIs(searchText))
                : .categories(.valueContains(searchText))
        )
        recipes += ingredients.flatMap(\.recipes.orEmpty)
        recipes += categories.flatMap(\.recipes.orEmpty)
        recipes = Array(Set(recipes))
        return .result(dialog: "Result") {
            cookleView {
                ForEach(recipes) { recipe in
                    VStack(alignment: .leading) {
                        Text(recipe.name)
                            .font(.headline)
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
                    }
                    .environment(recipe)
                }
            }
        }
    }

    static func performShowLastOpenedRecipe() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let id = AppStorage(.lastOpenedRecipeID).wrappedValue,
              let recipe = try context.fetchFirst(.recipes(.idIs(id))) else {
            return .result(dialog: "Not Found")
        }
        return .result(dialog: .init(stringLiteral: recipe.name)) {
            cookleView {
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

    static func performShowRandomRecipe() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let recipe = try context.fetchRandom(.recipes(.all)) else {
            return .result(dialog: "Not Found")
        }
        return .result(dialog: .init(stringLiteral: recipe.name)) {
            cookleView {
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

// MARK: - Private

private extension CookleIntents {
    static let modelContainer = try! ModelContainer(
        for: Recipe.self,
        configurations: .init(
            cloudKitDatabase: AppStorage(.isICloudOn).wrappedValue ? .automatic : .none
        )
    )

    static let context = modelContainer.mainContext

    static func cookleView(content: () -> some View) -> some View {
        content()
            .safeAreaPadding()
            .modelContainer(modelContainer)
            .cookleEnvironment(
                googleMobileAds: { _ in EmptyView() },
                licenseList: { EmptyView() },
                storeKit: { EmptyView() },
                appIntents: { EmptyView() }
            )
    }
}
