import Foundation
import SwiftData

/// Internal collaborator that reviews and applies a merge import.
///
/// Reviewing never changes the store. Applying rebuilds the review from the
/// current store, refuses to use an approval made against a different state,
/// validates every choice, and saves all changes at once or none of them.
@preconcurrency
@MainActor
enum CookleDataImportService {
    struct RecipeClassification {
        var newRecordIDs = [String]()
        var unchangedTargets = [String: PersistentIdentifier]()
        var conflicts = [CookleDataImportReview.RecipeConflict]()
    }

    /// A diary meal compared by meal and normalized recipe name.
    struct NamedMealKey: Equatable {
        let type: DiaryObjectType
        let recipeNameKey: String
    }

    struct DiaryClassification {
        var newRecordIDs = [String]()
        var unchangedTargets = [String: PersistentIdentifier]()
        var conflicts = [CookleDataImportReview.DiaryConflict]()
    }

    /// Builds the merge review for a validated archive without changing the store.
    static func review(
        for archive: CookleDataArchive,
        context: ModelContext,
        calendar: Calendar
    ) throws -> CookleDataImportReview {
        try CookleDataArchiveService.validate(archive, calendar: calendar, limits: .standard)
        let builder = CookleDataImportSnapshotBuilder(archive: archive)
        let currentRecipes = try context.fetch(.recipes(.all))
        let currentDiaries = try context.fetch(.diaries(.all))
        let recipes = classifyRecipes(
            archive: archive,
            currentRecipes: currentRecipes,
            builder: builder
        )
        let diaries = try classifyDiaries(
            archive: archive,
            currentDiaries: currentDiaries,
            calendar: calendar
        )
        return .init(
            calendar: calendar,
            isCurrentDataEmpty: try isEmpty(
                context: context,
                currentRecipes: currentRecipes,
                currentDiaries: currentDiaries
            ),
            newRecipeCount: recipes.newRecordIDs.count,
            unchangedRecipeCount: recipes.unchangedTargets.count,
            newDiaryCount: diaries.newRecordIDs.count,
            unchangedDiaryCount: diaries.unchangedTargets.count,
            recipeConflicts: recipes.conflicts,
            diaryConflicts: diaries.conflicts,
            archiveIdentity: try builder.archiveIdentity(),
            unchangedRecipeTargets: recipes.unchangedTargets,
            unchangedDiaryTargets: diaries.unchangedTargets
        )
    }

    /// Checks that `selections` resolves every conflict in `review` exactly once.
    nonisolated static func validate(
        _ selections: CookleDataImportSelections,
        for review: CookleDataImportReview
    ) throws {
        guard Set(selections.recipeChoices.keys) == Set(review.recipeConflicts.map(\.id)),
              Set(selections.diaryChoices.keys) == Set(review.diaryConflicts.map(\.id)) else {
            throw CookleDataImportError.invalidSelections
        }

        var replacedTargets = Set<PersistentIdentifier>()
        var keptTargets = Set(review.unchangedRecipeTargets.values)
        for conflict in review.recipeConflicts {
            let candidateIDs = Set(conflict.candidates.map(\.id))
            switch selections.recipeChoices[conflict.id] {
            case .keepCurrent(let target) where candidateIDs.contains(target):
                keptTargets.insert(target)
            case .useBackup(let target) where candidateIDs.contains(target):
                guard replacedTargets.insert(target).inserted else {
                    throw CookleDataImportError.invalidSelections
                }
            case .keepBoth:
                continue
            default:
                throw CookleDataImportError.invalidSelections
            }
        }
        // A recipe the file replaces cannot also stand for another imported recipe.
        guard replacedTargets.isDisjoint(with: keptTargets) else {
            throw CookleDataImportError.invalidSelections
        }
    }
}

private extension CookleDataImportService {
    static func classifyRecipes(
        archive: CookleDataArchive,
        currentRecipes: [Recipe],
        builder: CookleDataImportSnapshotBuilder
    ) -> RecipeClassification {
        let recipesByName = Dictionary(grouping: currentRecipes) { recipe in
            CookleDataImportSnapshotBuilder.nameKey(recipe.name)
        }
        var classification = RecipeClassification()
        for record in archive.recipes {
            let matches = (recipesByName[CookleDataImportSnapshotBuilder.nameKey(record.name)] ?? [])
                .sorted(by: isOrderedBefore)
            guard matches.isEmpty == false else {
                classification.newRecordIDs.append(record.id)
                continue
            }

            let backup = builder.snapshot(of: record)
            let candidates = matches.map { recipe in
                let current = builder.snapshot(of: recipe)
                return CookleDataImportReview.RecipeCandidate(
                    id: recipe.persistentModelID,
                    recipe: current,
                    diaryMealRowCount: (recipe.diaryObjects ?? []).count,
                    isIdenticalToBackup: current == backup,
                    diaryReview: .init(recipe: recipe)
                )
            }
            // Candidates are oldest first, so identical duplicates resolve to the oldest.
            if let target = candidates.first(where: \.isIdenticalToBackup) {
                classification.unchangedTargets[record.id] = target.id
            } else {
                classification.conflicts.append(
                    .init(
                        id: record.id,
                        backup: backup,
                        candidates: candidates
                    )
                )
            }
        }
        return classification
    }

    static func classifyDiaries(
        archive: CookleDataArchive,
        currentDiaries: [Diary],
        calendar: Calendar
    ) throws -> DiaryClassification {
        let diariesByDay = Dictionary(grouping: currentDiaries) { diary in
            calendar.startOfDay(for: diary.date)
        }
        let recipeNames = Dictionary(
            uniqueKeysWithValues: archive.recipes.map { recipe in
                (recipe.id, recipe.name)
            }
        )
        var classification = DiaryClassification()
        for record in archive.diaries {
            let day = calendar.startOfDay(for: record.date)
            let sameDay = diariesByDay[day] ?? []
            guard sameDay.count <= 1 else {
                throw CookleDataImportError.duplicateCurrentDiaryDays
            }
            guard let current = sameDay.first else {
                classification.newRecordIDs.append(record.id)
                continue
            }

            if isIdentical(record, to: current, recipeNames: recipeNames) {
                classification.unchangedTargets[record.id] = current.persistentModelID
                continue
            }
            classification.conflicts.append(
                .init(
                    id: record.id,
                    day: day,
                    current: snapshot(of: current),
                    backup: snapshot(of: record, recipeNames: recipeNames),
                    currentDiaryID: current.persistentModelID
                )
            )
        }
        return classification
    }

    /// An imported day equals the current one when the notes match and every
    /// meal, in order, shows a recipe with the same name.
    ///
    /// Comparing names rather than resolved recipes keeps an edited recipe from
    /// turning every day that shows it into a conflict; the recipe itself is
    /// reviewed separately.
    static func isIdentical(
        _ record: CookleDataArchive.DiaryRecord,
        to diary: Diary,
        recipeNames: [String: String]
    ) -> Bool {
        guard record.note == diary.note else {
            return false
        }

        let importedMeals = record.objects
            .sorted { lhs, rhs in
                (MealKey.index(of: lhs.type), lhs.order) < (MealKey.index(of: rhs.type), rhs.order)
            }
            .map { object in
                NamedMealKey(
                    type: object.type,
                    recipeNameKey: CookleDataImportSnapshotBuilder.nameKey(
                        recipeNames[object.recipeID] ?? ""
                    )
                )
            }
        let currentMeals = (diary.objects ?? [])
            .sorted { lhs, rhs in
                (MealKey.index(of: lhs.type), lhs.order) < (MealKey.index(of: rhs.type), rhs.order)
            }
            .compactMap { object -> NamedMealKey? in
                guard let type = object.type,
                      let recipe = object.recipe else {
                    return nil
                }
                return .init(
                    type: type,
                    recipeNameKey: CookleDataImportSnapshotBuilder.nameKey(recipe.name)
                )
            }
        return importedMeals == currentMeals
    }

    static func isEmpty(
        context: ModelContext,
        currentRecipes: [Recipe],
        currentDiaries: [Diary]
    ) throws -> Bool {
        guard currentRecipes.isEmpty,
              currentDiaries.isEmpty else {
            return false
        }
        return try context.fetchCount(.photos(.all)) == .zero
            && context.fetchCount(.ingredients(.all)) == .zero
            && context.fetchCount(.categories(.all)) == .zero
    }

    static func snapshot(of diary: Diary) -> CookleDataImportReview.DiarySnapshot {
        .init(
            meals: (diary.objects ?? [])
                .sorted { lhs, rhs in
                    (MealKey.index(of: lhs.type), lhs.order) < (MealKey.index(of: rhs.type), rhs.order)
                }
                .compactMap { object in
                    guard let type = object.type else {
                        return nil
                    }
                    return .init(
                        type: type,
                        recipeName: object.recipe?.name ?? "",
                        recipeID: object.recipe?.persistentModelID
                    )
                },
            note: diary.note
        )
    }

    static func snapshot(
        of record: CookleDataArchive.DiaryRecord,
        recipeNames: [String: String]
    ) -> CookleDataImportReview.DiarySnapshot {
        .init(
            meals: record.objects
                .sorted { lhs, rhs in
                    (MealKey.index(of: lhs.type), lhs.order) < (MealKey.index(of: rhs.type), rhs.order)
                }
                .map { object in
                    .init(type: object.type, recipeName: recipeNames[object.recipeID] ?? "", recipeID: nil)
                },
            note: record.note
        )
    }

    static func isOrderedBefore(_ lhs: Recipe, _ rhs: Recipe) -> Bool {
        if lhs.createdTimestamp != rhs.createdTimestamp {
            return lhs.createdTimestamp < rhs.createdTimestamp
        }
        return String(describing: lhs.persistentModelID) < String(describing: rhs.persistentModelID)
    }
}
