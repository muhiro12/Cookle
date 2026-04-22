import Foundation
import SwiftData

enum DiaryFormSaveCoordinator {
    struct Request {
        let diary: Diary?
        let date: Date
        let input: DiaryActionService.FormInput
    }

    @MainActor
    static func save(
        context: ModelContext,
        request: Request,
        diaryActionService: DiaryActionService
    ) async throws {
        if let diary = request.diary {
            try await diaryActionService.update(
                context: context,
                diary: diary,
                date: request.date,
                input: request.input
            )
            return
        }

        try await diaryActionService.create(
            context: context,
            date: request.date,
            input: request.input
        )
    }
}
