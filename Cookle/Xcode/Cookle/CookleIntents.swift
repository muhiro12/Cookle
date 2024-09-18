//
//  CookleIntents.swift
//  Cookle
//
//  Created by Hiromu Nakano on 9/8/24.
//

import AppIntents
import CooklePlaygrounds

struct OpenCookleIntent: AppIntent {
    static var title = LocalizedStringResource("Open Cookle")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try await CookleIntents.performOpenCookle()
    }
}

struct ShowLastOpenedRecipeIntent: AppIntent {
    static var title = LocalizedStringResource("Show Last Opened Recipe")

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        try await CookleIntents.performShowLastOpenedRecipe()
    }
}

struct ShowRandomRecipeIntent: AppIntent {
    static var title = LocalizedStringResource("Show Random Recipe")

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        try await CookleIntents.performShowRandomRecipe()
    }
}
