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
    ) -> MutationOutcome<Diary> {
        let diary = DiaryService.create(
            context: context,
            date: date,
            breakfasts: input.breakfasts,
            lunches: input.lunches,
            dinners: input.dinners,
            note: input.note
        )
        let effects: MutationEffect = [
            .diaryDataChanged
        ]
        applyEffects(effects)
        return .init(
            value: diary,
            effects: effects
        )
    }

    func update(
        context: ModelContext,
        diary: Diary,
        date: Date,
        input: FormInput
    ) -> MutationOutcome<Void> {
        DiaryService.update(
            context: context,
            diary: diary,
            date: date,
            breakfasts: input.breakfasts,
            lunches: input.lunches,
            dinners: input.dinners,
            note: input.note
        )
        let effects: MutationEffect = [
            .diaryDataChanged
        ]
        applyEffects(effects)
        return .init(
            value: (),
            effects: effects
        )
    }

    func update(
        context: ModelContext,
        on date: Date,
        input: FormInput
    ) async throws -> MutationOutcome<Diary?> {
        guard let diary = try DiaryService.diary(
            on: date,
            context: context
        ) else {
            return .init(value: nil)
        }

        let mutationOutcome = await update(
            context: context,
            diary: diary,
            date: date,
            input: input
        )
        return .init(
            value: diary,
            effects: mutationOutcome.effects
        )
    }

    func add(
        context: ModelContext,
        date: Date,
        recipe: Recipe,
        type: DiaryObjectType
    ) throws -> MutationOutcome<Diary> {
        let diary = try DiaryService.add(
            context: context,
            date: date,
            recipe: recipe,
            type: type
        )
        let effects: MutationEffect = [
            .diaryDataChanged
        ]
        applyEffects(effects)
        return .init(
            value: diary,
            effects: effects
        )
    }

    func delete(
        context: ModelContext,
        diary: Diary
    ) -> MutationOutcome<Void> {
        DiaryService.delete(
            context: context,
            diary: diary
        )
        let effects: MutationEffect = [
            .diaryDataChanged
        ]
        applyEffects(effects)
        return .init(
            value: (),
            effects: effects
        )
    }

    func delete(
        context: ModelContext,
        on date: Date
    ) async throws -> MutationOutcome<Bool> {
        guard let diary = try DiaryService.diary(
            on: date,
            context: context
        ) else {
            return .init(value: false)
        }

        let mutationOutcome = await delete(
            context: context,
            diary: diary
        )
        return .init(
            value: true,
            effects: mutationOutcome.effects
        )
    }
}

private extension DiaryActionService {
    func applyEffects(
        _ effects: MutationEffect
    ) {
        if effects.contains(.diaryDataChanged) {
            CookleWidgetReloader.reloadTodayDiaryWidget()
        }
    }
}
