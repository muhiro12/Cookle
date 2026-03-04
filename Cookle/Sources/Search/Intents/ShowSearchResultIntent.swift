//
//  ShowSearchResultIntent.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/16.
//

import AppIntents
import SwiftData
import SwiftUI

struct ShowSearchResultIntent: AppIntent {
    static var title: LocalizedStringResource {
        .init("Show Search Result")
    }

    @Parameter(title: "Search Text")
    private var searchText: String

    @Dependency private var modelContainer: ModelContainer

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let results = try RecipeService.search(
            context: modelContainer.mainContext,
            text: searchText
        )
        guard results.isNotEmpty else {
            return .result(dialog: "Not Found")
        }
        return .result(dialog: "Result") {
            SearchResultView(.anyTextMatches(searchText))
                .safeAreaPadding()
                .modelContainer(modelContainer)
        }
    }
}
