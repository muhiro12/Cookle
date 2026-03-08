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
        effectAdapter = CookleMutationEffectAdapter.make()
    }

    func create(
        context: ModelContext,
        date: Date,
        input: FormInput
    ) async -> MutationOutcome<Diary> {
        let effects = diaryMutationEffects
        let projection =
            MHMutationProjectionStrategy<
                PersistentIdentifier,
                MutationEffect,
                PersistentIdentifier
            >
            .fixedAdapterValue(effects)

        do {
            let persistentIdentifier = try await MHMutationWorkflow.runThrowing(
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
                projection: projection
            )
            return .init(
                value: diary(
                    for: persistentIdentifier,
                    context: context
                ),
                effects: effects
            )
        } catch {
            unexpectedFailure(
                error,
                name: "createDiary"
            )
        }
    }

    func update(
        context: ModelContext,
        diary: Diary,
        date: Date,
        input: FormInput
    ) async -> MutationOutcome<Void> {
        let effects = diaryMutationEffects
        let projection = MHMutationProjectionStrategy<Void, MutationEffect, Void>.fixedAdapterValue(
            effects
        )

        do {
            let _: Void = try await MHMutationWorkflow.runThrowing(
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
                projection: projection
            )
            return .init(
                value: (),
                effects: effects
            )
        } catch {
            unexpectedFailure(
                error,
                name: "updateDiary"
            )
        }
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
        let effects = diaryMutationEffects
        let projection =
            MHMutationProjectionStrategy<
                PersistentIdentifier,
                MutationEffect,
                PersistentIdentifier
            >
            .fixedAdapterValue(effects)
        let persistentIdentifier = try await MHMutationWorkflow.runThrowing(
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
            projection: projection
        )
        return .init(
            value: diary(
                for: persistentIdentifier,
                context: context
            ),
            effects: effects
        )
    }

    func delete(
        context: ModelContext,
        diary: Diary
    ) async -> MutationOutcome<Void> {
        let effects = diaryMutationEffects
        let projection = MHMutationProjectionStrategy<Void, MutationEffect, Void>.fixedAdapterValue(
            effects
        )

        do {
            let _: Void = try await MHMutationWorkflow.runThrowing(
                name: "deleteDiary",
                operation: {
                    DiaryService.delete(
                        context: context,
                        diary: diary
                    )
                },
                adapter: effectAdapter,
                projection: projection
            )
            return .init(
                value: (),
                effects: effects
            )
        } catch {
            unexpectedFailure(
                error,
                name: "deleteDiary"
            )
        }
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
    var diaryMutationEffects: MutationEffect {
        [
            .diaryDataChanged
        ]
    }

    func unexpectedFailure(
        _ error: any Error,
        name: String
    ) -> Never {
        assertionFailure(error.localizedDescription)
        preconditionFailure("Mutation unexpectedly failed: \(name)")
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
