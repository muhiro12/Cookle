import AppIntents
import SwiftData

struct UpdateDiaryIntent: AppIntent, IntentPerformer {
    typealias Input = (context: ModelContext, diary: Diary, date: Date, breakfasts: [Recipe], lunches: [Recipe], dinners: [Recipe], note: String)
    typealias Output = Void

    nonisolated static var title: LocalizedStringResource {
        "Update Diary"
    }

    static func perform(_ input: Input) {
        let (context, diary, date, breakfasts, lunches, dinners, note) = input
        let objects = zip(breakfasts.indices, breakfasts).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .breakfast, order: index + 1)
        } + zip(lunches.indices, lunches).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .lunch, order: index + 1)
        } + zip(dinners.indices, dinners).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .dinner, order: index + 1)
        }
        diary.update(
            date: date,
            objects: objects,
            note: note
        )
    }

    func perform() throws -> some IntentResult {
        .result()
    }
}
