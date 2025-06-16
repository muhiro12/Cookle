//
//  CookleIntents.swift
//  Cookle
//
//  Created by Hiromu Nakano on 9/8/24.
//

import AppIntents
import SwiftData
import SwiftUI
import SwiftUtilities

struct OpenCookleIntent: AppIntent, IntentPerformer {
    static var title = LocalizedStringResource("Open Cookle")
    static var openAppWhenRun = true

    typealias Input = Void
    typealias Output = Void

    @MainActor
    static func perform(_ input: Input) throws -> Output {}

    @MainActor
    func perform() throws -> some IntentResult {
        try Self.perform(())
        return .result()
    }
}

struct ShowSearchResultIntent: AppIntent, IntentPerformer {
    static var title = LocalizedStringResource("Show Search Result")

    @Parameter(title: "Search Text")
    private var searchText: String

    typealias Input = String
    typealias Output = [Recipe]

    @MainActor
    static func perform(_ input: Input) throws -> Output {
        let searchText = input
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
        _ = try Self.perform(searchText)
        return .result(dialog: "Result") {
            CookleIntents.cookleView {
                SearchResultView(.nameContains(searchText))
            }
        }
    }
}

struct ShowLastOpenedRecipeIntent: AppIntent, IntentPerformer {
    static var title = LocalizedStringResource("Show Last Opened Recipe")

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

struct ShowRandomRecipeIntent: AppIntent, IntentPerformer {
    static var title = LocalizedStringResource("Show Random Recipe")

    typealias Input = Void
    typealias Output = Recipe?

    @MainActor
    static func perform(_ input: Input) throws -> Output {
        try CookleIntents.context.fetchRandom(.recipes(.all))
    }

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let recipe = try Self.perform(()) else {
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
