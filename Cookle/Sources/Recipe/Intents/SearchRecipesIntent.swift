//
//  SearchRecipesIntent.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/07/12.
//

import AppIntents
import SwiftData

@MainActor
struct SearchRecipesIntent: AppIntent, IntentPerformer {
    typealias Input = (context: ModelContext, searchText: String)
    typealias Output = [Recipe]

    nonisolated static var title: LocalizedStringResource {
        "Search Recipes"
    }

    @Parameter(title: "Search for Recipes")
    private var searchText: String

    @Dependency private var modelContainer: ModelContainer

    static func perform(_ input: Input) throws -> Output {
        try RecipeService.search(context: input.context, text: input.searchText)
    }

    func perform() throws -> some ReturnsValue<[RecipeEntity]> {
        .result(
            value: try Self.perform(
                (
                    context: modelContainer.mainContext,
                    searchText: searchText
                )
            )
            .compactMap(RecipeEntity.init)
        )
    }
}
