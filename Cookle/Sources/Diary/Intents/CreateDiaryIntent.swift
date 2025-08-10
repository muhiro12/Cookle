//
//  CreateDiaryIntent.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/07/12.
//

import AppIntents
import SwiftData

@MainActor
struct CreateDiaryIntent: AppIntent {
    nonisolated static var title: LocalizedStringResource {
        "Create New Diary"
    }

    @Parameter(title: "Date")
    private var date: Date
    @Parameter(title: "Breakfasts")
    private var breakfasts: Set<RecipeEntity>
    @Parameter(title: "Lunches")
    private var lunches: Set<RecipeEntity>
    @Parameter(title: "Dinners")
    private var dinners: Set<RecipeEntity>
    @Parameter(title: "Note")
    private var note: String

    @Dependency private var modelContainer: ModelContainer

    func perform() throws -> some IntentResult {
        Logger(#file).info("Running CreateDiaryIntent")
        let context = modelContainer.mainContext
        let breakfastModels = breakfasts.compactMap { try? $0.model(context: context) }
        if breakfastModels.count != breakfasts.count {
            Logger(#file).error("Failed to convert some breakfasts")
        }
        let lunchModels = lunches.compactMap { try? $0.model(context: context) }
        if lunchModels.count != lunches.count {
            Logger(#file).error("Failed to convert some lunches")
        }
        let dinnerModels = dinners.compactMap { try? $0.model(context: context) }
        if dinnerModels.count != dinners.count {
            Logger(#file).error("Failed to convert some dinners")
        }
        _ = DiaryService.create(
            context: context,
            date: date,
            breakfasts: breakfastModels,
            lunches: lunchModels,
            dinners: dinnerModels,
            note: note
        )
        Logger(#file).notice("CreateDiaryIntent finished successfully")
        return .result()
    }
}
