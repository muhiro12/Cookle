import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class DiaryFormModel {
    var date = Date.now
    var breakfasts = Set<Recipe>()
    var lunches = Set<Recipe>()
    var dinners = Set<Recipe>()
    var note = ""
    var errorMessage: String?

    private var hasAppliedInitialValues = false

    var canSave: Bool {
        breakfasts.isEmpty == false
            || lunches.isEmpty == false
            || dinners.isEmpty == false
            || note
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isNotEmpty
    }

    var formInput: DiaryActionService.FormInput {
        .init(
            breakfasts: .init(breakfasts),
            lunches: .init(lunches),
            dinners: .init(dinners),
            note: note
        )
    }

    func applyInitialValues(
        diary: Diary?
    ) {
        guard hasAppliedInitialValues == false else {
            return
        }

        hasAppliedInitialValues = true
        date = diary?.date ?? .now
        breakfasts = recipes(
            for: diary,
            type: .breakfast
        )
        lunches = recipes(
            for: diary,
            type: .lunch
        )
        dinners = recipes(
            for: diary,
            type: .dinner
        )
        note = diary?.note ?? ""
    }

    func save(
        context: ModelContext,
        diary: Diary?,
        diaryActionService: DiaryActionService
    ) async -> Bool {
        do {
            errorMessage = nil
            try await DiaryFormSaveCoordinator.save(
                context: context,
                request: .init(
                    diary: diary,
                    date: date,
                    input: formInput
                ),
                diaryActionService: diaryActionService
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

private extension DiaryFormModel {
    func recipes(
        for diary: Diary?,
        type: DiaryObjectType
    ) -> Set<Recipe> {
        let recipes = diary?.objects.orEmpty
            .filter { object in
                object.type == type
            }
            .sorted()
            .compactMap(\.recipe) ?? []
        return .init(recipes)
    }
}
