//
//  CreateDiaryIntent.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/07/12.
//

import AppIntents
import SwiftData

@MainActor
struct CreateDiaryIntent: AppIntent, IntentPerformer {
    typealias Input = (context: ModelContext, date: Date, breakfasts: [Recipe], lunches: [Recipe], dinners: [Recipe], note: String)
    typealias Output = Diary

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

    static func perform(_ input: Input) -> Output {
        let (context, date, breakfasts, lunches, dinners, note) = input
        let objects = zip(breakfasts.indices, breakfasts).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .breakfast, order: index + 1)
        } + zip(lunches.indices, lunches).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .lunch, order: index + 1)
        } + zip(dinners.indices, dinners).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .dinner, order: index + 1)
        }
        return Diary.create(
            context: context,
            date: date,
            objects: objects,
            note: note
        )
    }

    func perform() throws -> some IntentResult {
        let context = modelContainer.mainContext
        _ = Self.perform(
            (
                context: context,
                date: date,
                breakfasts: breakfasts.compactMap { try? $0.model(context: context) },
                lunches: lunches.compactMap { try? $0.model(context: context) },
                dinners: dinners.compactMap { try? $0.model(context: context) },
                note: note
            )
        )
        return .result()
    }
}
