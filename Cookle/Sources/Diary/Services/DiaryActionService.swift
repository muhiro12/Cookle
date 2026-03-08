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
        let mutationOutcome = await CookleMutationWorkflow.run(
            name: "createDiary",
            operation: {
                DiaryService.create(
                    context: context,
                    date: date,
                    breakfasts: input.breakfasts,
                    lunches: input.lunches,
                    dinners: input.dinners,
                    note: input.note
                ).persistentModelID
            },
            adapter: effectAdapter,
            afterSuccess: diaryMutationEffects(for:)
        )
        return .init(
            value: diary(
                for: mutationOutcome.value,
                context: context
            ),
            effects: mutationOutcome.effects
        )
    }

    func update(
        context: ModelContext,
        diary: Diary,
        date: Date,
        input: FormInput
    ) async -> MutationOutcome<Void> {
        await CookleMutationWorkflow.run(
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
            },
            adapter: effectAdapter,
            afterSuccess: diaryMutationEffects(for:)
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
        let mutationOutcome = try await CookleMutationWorkflow.runThrowing(
            name: "addRecipeToDiary",
            operation: {
                try DiaryService.add(
                    context: context,
                    date: date,
                    recipe: recipe,
                    type: type
                ).persistentModelID
            },
            adapter: effectAdapter,
            afterSuccess: diaryMutationEffects(for:)
        )
        return .init(
            value: diary(
                for: mutationOutcome.value,
                context: context
            ),
            effects: mutationOutcome.effects
        )
    }

    func delete(
        context: ModelContext,
        diary: Diary
    ) async -> MutationOutcome<Void> {
        await CookleMutationWorkflow.run(
            name: "deleteDiary",
            operation: {
                DiaryService.delete(
                    context: context,
                    diary: diary
                )
            },
            adapter: effectAdapter,
            afterSuccess: diaryMutationEffects(for:)
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
    func diaryMutationEffects(
        for _: PersistentIdentifier
    ) -> MutationEffect {
        [
            .diaryDataChanged
        ]
    }

    func diaryMutationEffects(
        for _: Void
    ) -> MutationEffect {
        [
            .diaryDataChanged
        ]
    }

    func diary(
        for persistentIdentifier: PersistentIdentifier,
        context: ModelContext
    ) -> Diary {
        guard let diary = context.model(
            for: persistentIdentifier
        ) as? Diary else {
            preconditionFailure("Diary result was not resolved.")
        }
        return diary
    }
}
