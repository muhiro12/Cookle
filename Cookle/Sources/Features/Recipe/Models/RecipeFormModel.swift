import MHPlatform
import Observation
import SwiftData

@MainActor
@Observable
final class RecipeFormModel {
    let type: RecipeFormType

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

    var errorMessage: String?
    var savedRecipe: Recipe?
    var isPhotoConfirmationPresented = false
    var isImagePlaygroundPresented = false
    var isInferRecipeFromTextTipEligible = false
    var isImagePlaygroundTipEligible = false
    var hasRestorableSnapshot = false
    var isSaving = false

    private let snapshotStore: FormSnapshotStore<RecipeFormSnapshot>
    private var hasAppliedRecipe = false
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
        snapshotStore: FormSnapshotStore<RecipeFormSnapshot> = .init()
    ) {
        self.type = type
        self.snapshotStore = snapshotStore
    }

    func applyRecipeIfNeeded(
        _ recipe: Recipe?
    ) {
        guard let recipe else {
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
    }

    func makeDraft() throws -> RecipeFormDraft {
        try RecipeFormOperations.makeDraft(
            input: .init(
                name: name,
                photos: photos,
                servingSize: servingSize,
                cookingTime: cookingTime,
                ingredients: ingredients,
                steps: steps,
                categories: categories,
                note: note
            )
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
        recipe: Recipe?,
        recipeActionService: RecipeActionService,
        draftLogger: MHLogger
    ) async -> Bool {
        guard beginSaving() else {
            return false
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
                recipe: recipe,
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
            return false
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
        recipe: Recipe?,
        draft: RecipeFormDraft,
        recipeActionService: RecipeActionService
    ) async throws -> Bool {
        let result = try await RecipeFormSaveCoordinator.save(
            context: context,
            request: .init(
                type: type,
                recipe: recipe,
                draft: draft,
                requestReview: !photos.isEmpty
                    || CookleImagePlayground.isSupported == false
            ),
            recipeActionService: recipeActionService
        )

        return handleSaveResult(result)
    }

    func handleSaveResult(
        _ result: RecipeFormSaveCoordinator.Result
    ) -> Bool {
        switch result {
        case .created(let createdRecipe):
            savedRecipe = createdRecipe
            clearSnapshot()
            guard createdRecipe.photos?.isEmpty == false else {
                isPhotoConfirmationPresented = true
                return false
            }
            return true
        case .updated:
            clearSnapshot()
            return true
        }
    }
}

extension RecipeFormModel {
    func activateSnapshotPersistence(
        recipe: Recipe?
    ) {
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
