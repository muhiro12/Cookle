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
        diary: Diary?,
        prefill: DiaryFormPrefill? = nil
    ) {
        guard hasAppliedInitialValues == false else {
            return
        }

        hasAppliedInitialValues = true

        if let diary {
            apply(
                date: diary.date,
                breakfasts: recipes(
                    for: diary,
                    type: .breakfast
                ),
                lunches: recipes(
                    for: diary,
                    type: .lunch
                ),
                dinners: recipes(
                    for: diary,
                    type: .dinner
                ),
                note: diary.note
            )
            return
        }

        if let prefill {
            apply(
                date: prefill.date,
                breakfasts: prefill.breakfasts,
                lunches: prefill.lunches,
                dinners: prefill.dinners,
                note: prefill.note
            )
            return
        }

        apply(
            date: .now,
            breakfasts: [],
            lunches: [],
            dinners: [],
            note: ""
        )
    }

    func activateSnapshotPersistence(
        diary: Diary?
    ) {
        isSnapshotPersistenceEnabled = diary == nil
        refreshSnapshotAvailability()
    }

    func restoreSnapshot(
        context: ModelContext
    ) {
        guard isSnapshotPersistenceEnabled else {
            refreshSnapshotAvailability()
            return
        }

        guard let snapshot = snapshotStore.snapshot() else {
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

    func apply(
        date: Date,
        breakfasts: Set<Recipe>,
        lunches: Set<Recipe>,
        dinners: Set<Recipe>,
        note: String
    ) {
        self.date = date
        initialDate = date
        self.breakfasts = breakfasts
        self.lunches = lunches
        self.dinners = dinners
        self.note = note
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
        guard isSnapshotPersistenceEnabled else {
            return
        }

        snapshotStore.saveSnapshot(
            snapshot
        )
        refreshSnapshotAvailability()
    }

    func clearSnapshot() {
        guard isSnapshotPersistenceEnabled else {
            return
        }

        snapshotStore.removeSnapshot()
        refreshSnapshotAvailability()
    }

    func refreshSnapshotAvailability() {
        guard isSnapshotPersistenceEnabled else {
            hasRestorableSnapshot = false
            return
        }

        hasRestorableSnapshot = snapshotStore.hasSnapshot()
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
