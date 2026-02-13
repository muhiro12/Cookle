//
//  IntroductionTutorialSeeder.swift
//  Cookle
//
//  Created by Codex on 2026/02/14.
//

import SwiftData

enum IntroductionTutorialSeeder {
    static func seed(context: ModelContext) throws {
        let recipeCount = try context.fetchCount(
            FetchDescriptor<Recipe>()
        )
        guard recipeCount.isZero else {
            return
        }
        _ = try CooklePreviewStore().createPreviewDiaries(context)
    }
}
