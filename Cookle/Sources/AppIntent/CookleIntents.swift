//
//  CookleIntents.swift
//  Cookle
//
//  Created by Hiromu Nakano on 9/8/24.
//

import AppIntents
import SwiftData
import SwiftUI

struct OpenCookleIntent: AppIntent {
    static var title = LocalizedStringResource("Open Cookle")
    static var openAppWhenRun = true

    @MainActor
    func perform() throws -> some IntentResult {
        .result()
    }
}

struct ShowSearchResultIntent: AppIntent {
    static var title = LocalizedStringResource("Show Search Result")

    @Parameter(title: "Search Text")
    private var searchText: String

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        var recipes = try CookleIntents.context.fetch(
            .recipes(.nameContains(searchText))
        )
        let ingredients = try CookleIntents.context.fetch(
            searchText.count < 3
                ? .ingredients(.valueIs(searchText))
                : .ingredients(.valueContains(searchText))
        )
        let categories = try CookleIntents.context.fetch(
            searchText.count < 3
                ? .categories(.valueIs(searchText))
                : .categories(.valueContains(searchText))
        )
        recipes += ingredients.flatMap(\.recipes.orEmpty)
        recipes += categories.flatMap(\.recipes.orEmpty)
        recipes = Array(Set(recipes))
        return .result(dialog: "Result") {
            CookleIntents.cookleView {
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
}

struct ShowLastOpenedRecipeIntent: AppIntent {
    static var title = LocalizedStringResource("Show Last Opened Recipe")

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let id = AppStorage(.lastOpenedRecipeID).wrappedValue,
              let recipe = try CookleIntents.context.fetchFirst(.recipes(.idIs(id))) else {
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

struct ShowRandomRecipeIntent: AppIntent {
    static var title = LocalizedStringResource("Show Random Recipe")

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let recipe = try CookleIntents.context.fetchRandom(.recipes(.all)) else {
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

// MARK: - Private

@MainActor
enum CookleIntents {
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
