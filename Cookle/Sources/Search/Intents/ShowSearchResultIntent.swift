//
//  ShowSearchResultIntent.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/16.
//

import AppIntents
import SwiftData

@MainActor
struct ShowSearchResultIntent: AppIntent, IntentPerformer {
    typealias Input = (context: ModelContext, text: String)
    typealias Output = [Recipe]

    nonisolated static var title: LocalizedStringResource {
        .init("Show Search Result")
    }

    @Parameter(title: "Search Text")
    private var searchText: String

    @Dependency private var modelContainer: ModelContainer

    static func perform(_ input: Input) throws -> Output {
        try SearchService.search(context: input.context, text: input.text)
    }

    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        _ = try Self.perform((context: modelContainer.mainContext, text: searchText))
        return .result(dialog: "Result") {
            CookleIntents.cookleView {
                SearchResultView(.nameContains(searchText))
            }
        }
    }
}
