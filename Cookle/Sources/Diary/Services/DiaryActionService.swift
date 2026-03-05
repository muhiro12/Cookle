import Observation
import SwiftData

@MainActor
@Observable
final class DiaryActionService {
    struct FormInput {
        let breakfasts: [Recipe]
        let lunches: [Recipe]
        let dinners: [Recipe]
        let note: String
    }

    func create(
        context: ModelContext,
        date: Date,
        input: FormInput
    ) -> Diary {
        let diary = DiaryService.create(
            context: context,
            date: date,
            breakfasts: input.breakfasts,
            lunches: input.lunches,
            dinners: input.dinners,
            note: input.note
        )
        handleDiaryMutation()
        return diary
    }

    func update(
        context: ModelContext,
        diary: Diary,
        date: Date,
        input: FormInput
    ) {
        DiaryService.update(
            context: context,
            diary: diary,
            date: date,
            breakfasts: input.breakfasts,
            lunches: input.lunches,
            dinners: input.dinners,
            note: input.note
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
