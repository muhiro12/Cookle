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
        _ = try SearchService.search(
            context: modelContainer.mainContext,
            text: searchText
        )
        return .result(dialog: "Result") {
            SearchResultView(.nameContains(searchText))
                .safeAreaPadding()
                .modelContainer(modelContainer)
        }
    }
}
