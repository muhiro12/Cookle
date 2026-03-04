import Observation
import SwiftData

@MainActor
@Observable
final class DiaryActionService {
    func create(
        context: ModelContext,
        date: Date,
        breakfasts: [Recipe],
        lunches: [Recipe],
        dinners: [Recipe],
        note: String
    ) -> Diary {
        let diary = DiaryService.create(
            context: context,
            date: date,
            breakfasts: breakfasts,
            lunches: lunches,
            dinners: dinners,
            note: note
        )
        handleDiaryMutation()
        return diary
    }

    func update(
        context: ModelContext,
        diary: Diary,
        date: Date,
        breakfasts: [Recipe],
        lunches: [Recipe],
        dinners: [Recipe],
        note: String
    ) {
        DiaryService.update(
            context: context,
            diary: diary,
            date: date,
            breakfasts: breakfasts,
            lunches: lunches,
            dinners: dinners,
            note: note
        )
        handleDiaryMutation()
    }

    func add(
        context: ModelContext,
        date: Date,
        recipe: Recipe,
        type: DiaryObjectType
    ) throws -> Diary {
        let diary = try DiaryService.add(
            context: context,
            date: date,
            recipe: recipe,
            type: type
        )
        handleDiaryMutation()
        return diary
    }

    func delete(
        context: ModelContext,
        diary: Diary
    ) throws {
        try DiaryService.delete(
            context: context,
            diary: diary
        )
        handleDiaryMutation()
    }
}

private extension DiaryActionService {
    func handleDiaryMutation() {
        CookleWidgetReloader.reloadTodayDiaryWidget()
    }
}
