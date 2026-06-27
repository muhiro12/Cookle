import Foundation
import MHPlatform
import Observation
import SwiftData

@MainActor
@Observable
final class DiaryActionService {
    private let effectAdapter: MHMutationAdapter<MutationEffect>

    init() {
        effectAdapter = CookleMutationEffectAdapter.make()
    }

    @discardableResult
    func create(
        context: ModelContext,
        input: DiaryFormInput
    ) async throws -> MutationOutcome<Diary> {
        try await run(
            name: "createDiary"
        ) {
            DiaryOperations.createWithOutcome(
                context: context,
                input: input
            )
        }
    }

    @discardableResult
    func update(
        context: ModelContext,
        diary: Diary,
        input: DiaryFormInput
    ) async throws -> MutationOutcome<Diary> {
        try await run(
            name: "updateDiary"
        ) {
            DiaryOperations.updateWithOutcome(
                context: context,
                diary: diary,
                input: input
            )
        }
    }

    @discardableResult
    func update(
        context: ModelContext,
        input: DiaryFormInput
    ) async throws -> MutationOutcome<Diary?> {
        guard let diary = try DiaryOperations.diary(
            on: input.date,
            context: context
        ) else {
            return .init(value: nil)
        }

        let mutationOutcome = try await update(
            context: context,
            diary: diary,
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
            try DiaryOperations.addWithOutcome(
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
            DiaryOperations.deleteWithOutcome(
                context: context,
                diary: diary
            )
        }
    }
}

private extension DiaryActionService {
    func run<Value>(
        name: String,
        operation: @escaping @MainActor () throws -> MutationOutcome<Value>
    ) async throws -> MutationOutcome<Value> {
        try await CookleMutationWorkflow.run(
            name: name,
            adapter: effectAdapter,
            operation: operation
        )
    }
}
