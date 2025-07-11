//
//  ShowSearchResultIntent.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/16.
//

import AppIntents
import SwiftData

struct ShowSearchResultIntent: AppIntent, IntentPerformer {
    typealias Input = (context: ModelContext, text: String)
    typealias Output = [RecipeEntity]

    @Parameter(title: "Search Text")
    private var searchText: String

    @Dependency private var modelContainer: ModelContainer

    nonisolated static var title: LocalizedStringResource {
        .init("Show Search Result")
    }

    static func perform(_ input: Input) throws -> Output {
        let searchText = input.text
        var recipes = try input.context.fetch(
            .recipes(.nameContains(searchText))
        )
        let ingredients = try input.context.fetch(
            searchText.count < 3
                ? .ingredients(.valueIs(searchText))
                : .ingredients(.valueContains(searchText))
        )
        let categories = try input.context.fetch(
            searchText.count < 3
                ? .categories(.valueIs(searchText))
                : .categories(.valueContains(searchText))
        )
        recipes += ingredients.flatMap(\.recipes.orEmpty)
        recipes += categories.flatMap(\.recipes.orEmpty)
        recipes = Array(Set(recipes))
        return recipes.compactMap(RecipeEntity.init)
    }

    @MainActor func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        _ = try Self.perform((context: modelContainer.mainContext, text: searchText))
        return .result(dialog: "Result") {
            CookleIntents.cookleView {
                SearchResultView(.nameContains(searchText))
            }
        }
    }
}
