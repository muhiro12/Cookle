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
    static func perform() throws -> some IntentResult {
        .result()
    }

    @MainActor
    func perform() throws -> some IntentResult {
        try Self.perform()
    }
}

struct ShowSearchResultIntent: AppIntent {
    static var title = LocalizedStringResource("Show Search Result")

    @Parameter(title: "Search Text")
    private var searchText: String

    @MainActor
    static func perform(searchText: String) throws -> [Recipe] {
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
        return recipes
    }

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let recipes = try Self.perform(searchText: searchText)
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
    static func perform(id: PersistentIdentifier?) throws -> Recipe? {
        guard let id else { return nil }
        return try CookleIntents.context.fetchFirst(.recipes(.idIs(id)))
    }

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let recipe = try Self.perform(id: AppStorage(.lastOpenedRecipeID).wrappedValue) else {
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
    static func perform() throws -> Recipe? {
        try CookleIntents.context.fetchRandom(.recipes(.all))
    }

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let recipe = try Self.perform() else {
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
