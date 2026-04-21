import SwiftData

/// Cleans up parent-owned rows that were left detached by older update flows.
enum DetachedObjectCleanupService {
    struct Report: Equatable {
        let deletedDiaryObjectCount: Int
        let deletedPhotoObjectCount: Int
        let deletedIngredientObjectCount: Int

        var totalDeletedObjectCount: Int {
            deletedDiaryObjectCount
                + deletedPhotoObjectCount
                + deletedIngredientObjectCount
        }
    }

    enum Outcome: Equatable {
        case skippedAlreadyCompleted
        case performed(Report)
    }

    @discardableResult
    static func runIfNeeded(
        context: ModelContext
    ) throws -> Outcome {
        try runIfNeeded(
            context: context,
            isCompleted: {
                CooklePreferences.bool(for: \.detachedObjectCleanupCompleted)
            },
            markCompleted: {
                CooklePreferences.set(
                    true,
                    for: \.detachedObjectCleanupCompleted
                )
            }
        )
    }

    @discardableResult
    static func runIfNeeded(
        context: ModelContext,
        isCompleted: () -> Bool,
        markCompleted: () -> Void
    ) throws -> Outcome {
        guard !isCompleted() else {
            return .skippedAlreadyCompleted
        }

        let report = try cleanupDetachedObjects(
            context: context
        )
        if report.totalDeletedObjectCount > .zero {
            try context.save()
        }
        markCompleted()
        return .performed(report)
    }
}

private extension DetachedObjectCleanupService {
    static func cleanupDetachedObjects(
        context: ModelContext
    ) throws -> Report {
        let detachedDiaryObjects = try context.fetch(
            FetchDescriptor<DiaryObject>()
        ).filter { diaryObject in
            diaryObject.diary == nil
        }
        let detachedPhotoObjects = try context.fetch(
            FetchDescriptor<PhotoObject>()
        ).filter { photoObject in
            photoObject.recipe == nil
        }
        let detachedIngredientObjects = try context.fetch(
            FetchDescriptor<IngredientObject>()
        ).filter { ingredientObject in
            ingredientObject.recipe == nil
        }

        detachedDiaryObjects.forEach(context.delete)
        detachedPhotoObjects.forEach(context.delete)
        detachedIngredientObjects.forEach(context.delete)

        return .init(
            deletedDiaryObjectCount: detachedDiaryObjects.count,
            deletedPhotoObjectCount: detachedPhotoObjects.count,
            deletedIngredientObjectCount: detachedIngredientObjects.count
        )
    }
}
