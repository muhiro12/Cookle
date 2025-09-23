//
//  SearchRecipesIntent.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/07/12.
//

import AppIntents
import SwiftData

struct SearchRecipesIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Search Recipes"
    }

    @Parameter(title: "Search for Recipes")
    private var searchText: String

    @Dependency private var modelContainer: ModelContainer

    @MainActor
    func perform() throws -> some ReturnsValue<[RecipeEntity]> {
        .result(
            value: try RecipeService.search(
                context: modelContainer.mainContext,
                text: searchText
            )
            .compactMap(RecipeEntity.init)
        )
    }
}
