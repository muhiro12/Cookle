//
//  ShowSearchResultIntent.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/16.
//

import AppIntents
import SwiftData

@MainActor
struct ShowSearchResultIntent: AppIntent {
    nonisolated static var title: LocalizedStringResource {
        .init("Show Search Result")
    }

    @Parameter(title: "Search Text")
    private var searchText: String

    @Dependency private var modelContainer: ModelContainer

    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        _ = try SearchService.search(
            context: modelContainer.mainContext,
            text: searchText
        )
        return .result(dialog: "Result") {
            CookleIntents.cookleView {
                SearchResultView(.nameContains(searchText))
            }
        }
    }
}
