//
//  ShowSearchResultIntent.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/16.
//

import AppIntents
import SwiftData
import SwiftUtilities

struct ShowSearchResultIntent: AppIntent, IntentPerformer {
    typealias Input = (container: ModelContainer, text: String)
    typealias Output = [RecipeEntity]

    @Parameter(title: "Search Text")
    private var searchText: String

    @Dependency private var modelContainer: ModelContainer

    static var title: LocalizedStringResource {
        .init("Show Search Result")
    }

    @MainActor
    static func perform(_ input: Input) throws -> Output {
        let searchText = input.text
        var recipes = try input.container.mainContext.fetch(
            .recipes(.nameContains(searchText))
        )
        let ingredients = try input.container.mainContext.fetch(
            searchText.count < 3
                ? .ingredients(.valueIs(searchText))
                : .ingredients(.valueContains(searchText))
        )
        let categories = try input.container.mainContext.fetch(
            searchText.count < 3
                ? .categories(.valueIs(searchText))
                : .categories(.valueContains(searchText))
        )
        recipes += ingredients.flatMap(\.recipes.orEmpty)
        recipes += categories.flatMap(\.recipes.orEmpty)
        recipes = Array(Set(recipes))
        return recipes.compactMap(RecipeEntity.init)
    }

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        _ = try Self.perform((container: modelContainer, text: searchText))
        return .result(dialog: "Result") {
            CookleIntents.cookleView {
                SearchResultView(.nameContains(searchText))
            }
        }
    }
}
