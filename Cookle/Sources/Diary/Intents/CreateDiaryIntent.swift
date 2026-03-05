//
//  CreateDiaryIntent.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/07/12.
//

import AppIntents
import SwiftData

struct CreateDiaryIntent: AppIntent {
    static var title: LocalizedStringResource {
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
    @Dependency private var diaryActionService: DiaryActionService

    @MainActor
    func perform() async -> some IntentResult {
        let context = modelContainer.mainContext
        _ = await diaryActionService.create(
            context: context,
            date: date,
            input: .init(
                breakfasts: DiaryIntentSupport.resolveRecipes(
                    from: breakfasts,
                    context: context
                ),
                lunches: DiaryIntentSupport.resolveRecipes(
                    from: lunches,
                    context: context
                ),
                dinners: DiaryIntentSupport.resolveRecipes(
                    from: dinners,
                    context: context
                ),
                note: note
            )
        )
        return .result()
    }
}
