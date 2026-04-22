import Foundation
import MHPlatform
import Observation
import SwiftData

@MainActor
@Observable
final class DiaryActionService {
    private struct OperationResult<Value> {
        let value: Value
        let effects: MutationEffect
    }

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

    @discardableResult
    func create(
        context: ModelContext,
        date: Date,
        input: FormInput
    ) async throws -> MutationOutcome<Diary> {
        try await run(
            name: "createDiary"
        ) {
            DiaryService.createWithOutcome(
                context: context,
                date: date,
                breakfasts: input.breakfasts,
                lunches: input.lunches,
                dinners: input.dinners,
                note: input.note
            )
        }
    }

    @discardableResult
    func update(
        context: ModelContext,
        diary: Diary,
        date: Date,
        input: FormInput
    ) async throws -> MutationOutcome<Diary> {
        try await run(
            name: "updateDiary"
        ) {
            DiaryService.updateWithOutcome(
                context: context,
                diary: diary,
                date: date,
                breakfasts: input.breakfasts,
                lunches: input.lunches,
                dinners: input.dinners,
                note: input.note
            )
        }
    }

    @discardableResult
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

        let mutationOutcome = try await update(
            context: context,
            diary: diary,
            date: date,
            input: input
        )
        return .init(
            value: mutationOutcome.value,
            effects: mutationOutcome.effects
        )
    }

    @discardableResult
    func add(
        context: ModelContext,
        date: Date,
        recipe: Recipe,
        type: DiaryObjectType
    ) async throws -> MutationOutcome<Diary> {
        try await run(
            name: "addRecipeToDiary"
        ) {
            try DiaryService.addWithOutcome(
                context: context,
                date: date,
                recipe: recipe,
                type: type
            )
        }
    }

    @discardableResult
    func delete(
        context: ModelContext,
        diary: Diary
    ) async throws -> MutationOutcome<Void> {
        try await run(
            name: "deleteDiary"
        ) {
            DiaryService.deleteWithOutcome(
                context: context,
                diary: diary
            )
        }
    }

    @discardableResult
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

        let mutationOutcome = try await delete(
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
    func run<Value>(
        name: String,
        operation: @escaping @MainActor () throws -> MutationOutcome<Value>
    ) async throws -> MutationOutcome<Value> {
        let result = try await MHMutationWorkflow.runThrowing(
            name: name,
            operation: {
                let outcome = try operation()
                return OperationResult(
                    value: outcome.value,
                    effects: outcome.effects
                )
            },
            adapter: effectAdapter,
            projection: .closures(
                afterSuccess: { result in
                    result.effects
                },
                returning: { result in
                    result
                }
            )
        )
        return .init(
            value: result.value,
            effects: result.effects
        )
    }
}
