//
//  ShowSearchResultIntent.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/16.
//

import AppIntents
import SwiftUtilities

struct ShowSearchResultIntent: AppIntent, IntentPerformer {
    static var title: LocalizedStringResource {
        .init("Show Search Result")
    }

    @Parameter(title: "Search Text")
    private var searchText: String

    typealias Input = String
    typealias Output = [RecipeEntity]

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
        return recipes.compactMap(RecipeEntity.init)
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
