import Foundation
import MHPlatform
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

    private let effectAdapter: MHMutationAdapter<MutationEffect>

    init() {
        effectAdapter = CookleMutationWorkflow.effectAdapter()
    }

    func create(
        context: ModelContext,
        date: Date,
        input: FormInput
    ) async -> MutationOutcome<Diary> {
        let diaryStore = CookleMutationWorkflow.ValueStore<Diary>()
        let effects = await CookleMutationWorkflow.run(
            name: "createDiary",
            operation: {
                let diary = DiaryService.create(
                    context: context,
                    date: date,
                    breakfasts: input.breakfasts,
                    lunches: input.lunches,
                    dinners: input.dinners,
                    note: input.note
                )
                diaryStore.value = diary
                return [
                    .diaryDataChanged
                ]
            },
            adapter: effectAdapter
        )

        guard let diary = diaryStore.value else {
            preconditionFailure("Diary result was not captured.")
        }

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
    ) async -> MutationOutcome<Void> {
        let effects = await CookleMutationWorkflow.run(
            name: "updateDiary",
            operation: {
                DiaryService.update(
                    context: context,
                    diary: diary,
                    date: date,
                    breakfasts: input.breakfasts,
                    lunches: input.lunches,
                    dinners: input.dinners,
                    note: input.note
                )
                return [
                    .diaryDataChanged
                ]
            },
            adapter: effectAdapter
        )
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
    ) async throws -> MutationOutcome<Diary> {
        let diaryStore = CookleMutationWorkflow.ValueStore<Diary>()
        let effects = try await CookleMutationWorkflow.runThrowing(
            name: "addRecipeToDiary",
            operation: {
                let diary = try DiaryService.add(
                    context: context,
                    date: date,
                    recipe: recipe,
                    type: type
                )
                diaryStore.value = diary
                return [
                    .diaryDataChanged
                ]
            },
            adapter: effectAdapter
        )

        guard let diary = diaryStore.value else {
            preconditionFailure("Diary result was not captured.")
        }

        return .init(
            value: diary,
            effects: effects
        )
    }

    func delete(
        context: ModelContext,
        diary: Diary
    ) async -> MutationOutcome<Void> {
        let effects = await CookleMutationWorkflow.run(
            name: "deleteDiary",
            operation: {
                DiaryService.delete(
                    context: context,
                    diary: diary
                )
                return [
                    .diaryDataChanged
                ]
            },
            adapter: effectAdapter
        )
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
