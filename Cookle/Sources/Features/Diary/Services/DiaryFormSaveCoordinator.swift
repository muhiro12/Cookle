import SwiftData

enum DiaryFormSaveCoordinator {
    @MainActor
    static func save(
        context: ModelContext,
        diary: Diary?,
        input: DiaryFormInput,
        diaryActionService: DiaryActionService
    ) async throws {
        if let diary {
            try await diaryActionService.update(
                context: context,
                diary: diary,
                input: input
            )
            return
        }

        try await diaryActionService.create(
            context: context,
            input: input
        )
    }
}
