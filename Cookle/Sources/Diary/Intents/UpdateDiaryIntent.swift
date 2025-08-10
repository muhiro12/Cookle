//
//  UpdateDiaryIntent.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/07/12.
//

import AppIntents
import SwiftData

@MainActor
struct UpdateDiaryIntent: AppIntent, IntentPerformer {
    typealias Input = (context: ModelContext, diary: Diary, date: Date, breakfasts: [Recipe], lunches: [Recipe], dinners: [Recipe], note: String)
    typealias Output = Void

    nonisolated static var title: LocalizedStringResource {
        "Update Diary"
    }

    nonisolated static var isDiscoverable: Bool {
        false
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

    static func perform(_ input: Input) {
        DiaryService.update(
            context: input.context,
            diary: input.diary,
            date: input.date,
            breakfasts: input.breakfasts,
            lunches: input.lunches,
            dinners: input.dinners,
            note: input.note
        )
    }

    func perform() throws -> some IntentResult {
        .result()
    }
}
