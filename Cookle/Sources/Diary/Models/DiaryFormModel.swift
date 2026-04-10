import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class DiaryFormModel {
    var date = Date.now {
        didSet {
            persistSnapshotIfNeeded()
        }
    }
    var breakfasts = Set<Recipe>() {
        didSet {
            persistSnapshotIfNeeded()
        }
    }
    var lunches = Set<Recipe>() {
        didSet {
            persistSnapshotIfNeeded()
        }
    }
    var dinners = Set<Recipe>() {
        didSet {
            persistSnapshotIfNeeded()
        }
    }
    var note = "" {
        didSet {
            persistSnapshotIfNeeded()
        }
    }
    var errorMessage: String?
    var hasRestorableSnapshot = false

    private let snapshotStore: FormSnapshotStore<DiaryFormSnapshot>
    private var hasAppliedInitialValues = false
    private var initialDate = Date.now
    private var isSnapshotPersistenceEnabled = false
    private var snapshotKey: String?

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

    var restorePolicy: FormSnapshotRestorePolicy {
        .init(
            hasSnapshot: hasRestorableSnapshot,
            isCurrentInputNearlyEmpty: isFormNearlyEmpty
        )
    }

    init(
        snapshotStore: FormSnapshotStore<DiaryFormSnapshot> = .init()
    ) {
        self.snapshotStore = snapshotStore
    }

    func applyInitialValues(
        diary: Diary?
    ) {
        guard hasAppliedInitialValues == false else {
            return
        }

        hasAppliedInitialValues = true
        date = diary?.date ?? .now
        initialDate = date
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

    func activateSnapshotPersistence(
        diary: Diary?
    ) {
        snapshotKey = DiaryFormSnapshot.key(
            for: diary
        )
        isSnapshotPersistenceEnabled = true
        refreshSnapshotAvailability()
    }

    func restoreSnapshot(
        context: ModelContext
    ) {
        guard let snapshotKey,
              let snapshot = snapshotStore.snapshot(
                for: snapshotKey
              ) else {
            refreshSnapshotAvailability()
            return
        }

        performWithoutSnapshotPersistence {
            date = snapshot.date
            breakfasts = restoredRecipes(
                from: snapshot.breakfastRecipeIDs,
                context: context
            )
            lunches = restoredRecipes(
                from: snapshot.lunchRecipeIDs,
                context: context
            )
            dinners = restoredRecipes(
                from: snapshot.dinnerRecipeIDs,
                context: context
            )
            note = snapshot.note
        }
        refreshSnapshotAvailability()
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
            clearSnapshot()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

private extension DiaryFormModel {
    var isFormNearlyEmpty: Bool {
        snapshot.isNearlyEmpty(
            comparedTo: initialDate
        )
    }

    var snapshot: DiaryFormSnapshot {
        .init(
            date: date,
            breakfastRecipeIDs: stableIdentifiers(
                for: breakfasts
            ),
            lunchRecipeIDs: stableIdentifiers(
                for: lunches
            ),
            dinnerRecipeIDs: stableIdentifiers(
                for: dinners
            ),
            note: note
        )
    }

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

    func restoredRecipes(
        from stableIdentifiers: [String],
        context: ModelContext
    ) -> Set<Recipe> {
        let recipes: [Recipe] = stableIdentifiers.compactMap { stableIdentifier in
            let resolvedRecipe = try? RecipeStableIdentifierCodec.recipe(
                from: stableIdentifier,
                context: context
            )
            guard let recipe = resolvedRecipe else {
                return nil
            }

            return recipe
        }
        return .init(recipes)
    }

    func stableIdentifiers(
        for recipes: Set<Recipe>
    ) -> [String] {
        recipes.map { recipe in
            RecipeStableIdentifierCodec.stableIdentifier(
                for: recipe
            )
        }
        .sorted()
    }

    func persistSnapshotIfNeeded() {
        guard isSnapshotPersistenceEnabled,
              let snapshotKey else {
            return
        }

        snapshotStore.saveSnapshot(
            snapshot,
            for: snapshotKey
        )
        refreshSnapshotAvailability()
    }

    func clearSnapshot() {
        guard let snapshotKey else {
            return
        }

        snapshotStore.removeSnapshot(
            for: snapshotKey
        )
        refreshSnapshotAvailability()
    }

    func refreshSnapshotAvailability() {
        guard let snapshotKey else {
            hasRestorableSnapshot = false
            return
        }

        hasRestorableSnapshot = snapshotStore.hasSnapshot(
            for: snapshotKey
        )
    }

    func performWithoutSnapshotPersistence(
        _ updates: () -> Void
    ) {
        let wasEnabled = isSnapshotPersistenceEnabled
        isSnapshotPersistenceEnabled = false
        updates()
        isSnapshotPersistenceEnabled = wasEnabled
    }
}
