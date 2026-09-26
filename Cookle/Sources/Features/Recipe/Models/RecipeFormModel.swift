import MHPlatform
import Observation
import SwiftData

/// Editing state for one open recipe form.
///
/// A presentation host owns each instance, so the draft, including attached
/// photos, outlives the views that render it when a size-class change rebuilds
/// them.
@MainActor
@Observable
final class RecipeFormModel: Identifiable {
    let type: RecipeFormType
    /// The recipe being edited or duplicated; `nil` when creating.
    let recipe: Recipe?

    var name = "" {
        didSet {
            persistSnapshotIfNeeded()
        }
    }
    var photos = [PhotoData]()
    var servingSize = "" {
        didSet {
            persistSnapshotIfNeeded()
        }
    }
    var cookingTime = "" {
        didSet {
            persistSnapshotIfNeeded()
        }
    }
    var ingredients = [RecipeFormIngredient]() {
        didSet {
            persistSnapshotIfNeeded()
        }
    }
    var steps = [String]() {
        didSet {
            persistSnapshotIfNeeded()
        }
    }
    var categories = [String]() {
        didSet {
            persistSnapshotIfNeeded()
        }
    }
    var note = "" {
        didSet {
            persistSnapshotIfNeeded()
        }
    }

    /// Import flow presented over the form, owned here so it is not reopened
    /// or lost when the form's views are rebuilt.
    var importSource: RecipeImportSource?
    /// The latest inferred recipe applied to this form, kept for one undo.
    var inferenceApplication: RecipeInferenceApplication?
    var errorMessage: String?
    var isInferRecipeFromTextTipEligible = false
    var isImagePlaygroundTipEligible = false
    var hasRestorableSnapshot = false
    var isSaving = false

    private let snapshotStore: FormSnapshotStore<RecipeFormSnapshot>
    private var hasAppliedRecipe = false
    var initialChangeSnapshot: RecipeFormChangeSnapshot?
    private var isSnapshotPersistenceEnabled = false

    var isCreateFlow: Bool {
        switch type {
        case .create:
            true
        case .duplicate,
             .edit:
            false
        }
    }

    var isRecipeDraftNearlyEmpty: Bool {
        name.isEmpty
            && photos.isEmpty
            && servingSize.isEmpty
            && cookingTime.isEmpty
            && note.isEmpty
            && ingredients.allSatisfy { ingredient in
                ingredient.ingredient.isEmpty && ingredient.amount.isEmpty
            }
            && steps.allSatisfy(\.isEmpty)
            && categories.allSatisfy(\.isEmpty)
    }

    var shouldShowInferRecipeFromTextTip: Bool {
        guard #available(iOS 26.0, *) else {
            return false
        }
        guard isCreateFlow else {
            return false
        }

        return isRecipeDraftNearlyEmpty && isInferRecipeFromTextTipEligible
    }

    var shouldShowImagePlaygroundTip: Bool {
        guard isCreateFlow else {
            return false
        }

        return CookleImagePlayground.isSupported
            && photos.isEmpty
            && isImagePlaygroundTipEligible
            && shouldShowInferRecipeFromTextTip == false
    }

    var restorePolicy: FormSnapshotRestorePolicy {
        .init(
            hasSnapshot: hasRestorableSnapshot,
            isCurrentInputNearlyEmpty: isRecipeDraftNearlyEmpty
        )
    }

    init(
        type: RecipeFormType,
        recipe: Recipe? = nil,
        importSource: RecipeImportSource? = nil,
        snapshotStore: FormSnapshotStore<RecipeFormSnapshot> = .init()
    ) {
        self.type = type
        self.recipe = recipe
        self.importSource = importSource
        self.snapshotStore = snapshotStore
    }

    func applyRecipeIfNeeded() {
        guard let recipe else {
            captureInitialChangeSnapshotIfNeeded()
            return
        }
        guard hasAppliedRecipe == false else {
            return
        }

        hasAppliedRecipe = true
        name = recipe.name
        photos = recipe.orderedPhotos.map { photo in
            .init(
                data: photo.data,
                source: photo.source
            )
        }
        servingSize = recipe.servingSize.description
        cookingTime = recipe.cookingTime.description
        ingredients = (recipe.ingredientObjects?
                        .sorted()
                        .compactMap { object in
                            guard let ingredient = object.ingredient else {
                                return nil
                            }
                            return .init(
                                ingredient: ingredient.value,
                                amount: object.amount
                            )
                        } ?? []) + [.init(ingredient: "", amount: "")]
        steps = recipe.steps + [""]
        categories = (recipe.categories?.map(\.value) ?? []) + [""]
        note = recipe.note
        captureInitialChangeSnapshotIfNeeded()
    }

    func makeDraft() throws -> RecipeFormDraft {
        try RecipeFormOperations.makeDraft(
            input: formInput
        )
    }

    func updateInferRecipeFromTextTipEligibility(
        _ shouldDisplay: Bool
    ) {
        isInferRecipeFromTextTipEligible = shouldDisplay
    }

    func updateImagePlaygroundTipEligibility(
        _ shouldDisplay: Bool
    ) {
        isImagePlaygroundTipEligible = shouldDisplay
    }

    func save(
        context: ModelContext,
        recipeActionService: RecipeActionService,
        draftLogger: MHLogger
    ) async -> RecipeFormSaveCoordinator.Result? {
        guard beginSaving() else {
            return nil
        }
        defer {
            isSaving = false
        }

        let draftSummary = RecipeDraftLogging.formSummary(
            type: type,
            ingredients: ingredients,
            steps: steps,
            categories: categories,
            note: note
        )

        do {
            errorMessage = nil
            let draft = try makeDraft()
            logDraftSuccess(
                draft,
                summary: draftSummary,
                logger: draftLogger
            )
            return try await save(
                context: context,
                draft: draft,
                recipeActionService: recipeActionService
            )
        } catch {
            RecipeDraftLogging.logFailure(
                logger: draftLogger,
                summary: draftSummary,
                error: error
            )
            errorMessage = error.localizedDescription
            return nil
        }
    }
}

private extension RecipeFormModel {
    func beginSaving() -> Bool {
        guard isSaving == false else {
            return false
        }

        isSaving = true
        return true
    }

    func logDraftSuccess(
        _ draft: RecipeFormDraft,
        summary: RecipeDraftLogging.Summary,
        logger: MHLogger
    ) {
        RecipeDraftLogging.logSuccess(
            logger: logger,
            summary: summary,
            draft: draft
        )
    }

    func save(
        context: ModelContext,
        draft: RecipeFormDraft,
        recipeActionService: RecipeActionService
    ) async throws -> RecipeFormSaveCoordinator.Result {
        let result = try await RecipeFormSaveCoordinator.save(
            context: context,
            type: type,
            recipe: recipe,
            draft: draft,
            recipeActionService: recipeActionService
        )

        acceptCurrentChanges()
        clearSnapshot()
        return result
    }
}

extension RecipeFormModel {
    func activateSnapshotPersistence() {
        isSnapshotPersistenceEnabled = type == .create
            && recipe == nil
        refreshSnapshotAvailability()
    }

    func restoreSnapshot() {
        guard isSnapshotPersistenceEnabled else {
            refreshSnapshotAvailability()
            return
        }

        guard let snapshot = snapshotStore.snapshot() else {
            refreshSnapshotAvailability()
            return
        }

        performWithoutSnapshotPersistence {
            name = snapshot.name
            servingSize = snapshot.servingSize
            cookingTime = snapshot.cookingTime
            ingredients = RecipeFormPlaceholderRows.normalizedIngredients(
                snapshot.formIngredients
            )
            steps = RecipeFormPlaceholderRows.normalizedStrings(
                snapshot.steps
            )
            categories = RecipeFormPlaceholderRows.normalizedStrings(
                snapshot.categories
            )
            note = snapshot.note
        }
        refreshSnapshotAvailability()
    }
}

private extension RecipeFormModel {
    var snapshot: RecipeFormSnapshot {
        .init(
            name: name,
            servingSize: servingSize,
            cookingTime: cookingTime,
            ingredients: ingredients,
            steps: steps,
            categories: categories,
            note: note
        )
    }

    func persistSnapshotIfNeeded() {
        guard isSnapshotPersistenceEnabled else {
            return
        }

        // Opening the form settles its bindings and writes the empty state
        // before the user can reach Restore Draft. Persisting that would
        // destroy the very draft the button exists to recover.
        guard !snapshot.isEmpty else {
            refreshSnapshotAvailability()
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
