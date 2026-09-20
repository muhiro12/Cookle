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
        let results = try RecipeOperations.search(
            context: modelContainer.mainContext,
            text: searchText
        )
        guard !results.isEmpty else {
            return .result(
                dialog: .init(
                    stringLiteral: String(localized: "Not Found")
                )
            )
        }
        return .result(
            dialog: .init(
                stringLiteral: String(localized: "Result")
            )
        ) {
            SearchResultView(.anyTextMatches(searchText))
                .environment(CookleRouteNavigator.disabled)
                .safeAreaPadding()
                .modelContainer(modelContainer)
        }
    }
}
