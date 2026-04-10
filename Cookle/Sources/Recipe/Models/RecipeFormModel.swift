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

    private let snapshotStore: FormSnapshotStore<RecipeFormSnapshot>
    private var hasAppliedRecipe = false
    private var isSnapshotPersistenceEnabled = false
    private var snapshotKey: String?

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
        photos = recipe.photoObjects?
            .sorted()
            .compactMap { photoObject in
                guard let photo = photoObject.photo else {
                    return nil
                }
                return .init(
                    data: photo.data,
                    source: photo.source
                )
            } ?? .empty
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
                        } ?? .empty) + [.init(ingredient: .empty, amount: .empty)]
        steps = recipe.steps + [.empty]
        categories = (recipe.categories?.map(\.value) ?? .empty) + [.empty]
        note = recipe.note
    }

    func makeDraft() throws -> RecipeFormDraft {
        try RecipeFormService.makeDraft(
            name: name,
            photos: photos,
            servingSize: servingSize,
            cookingTime: cookingTime,
            ingredients: ingredients,
            steps: steps,
            categories: categories,
            note: note
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
            RecipeDraftLogging.logSuccess(
                logger: draftLogger,
                summary: draftSummary,
                draft: draft
            )
            let result = try await RecipeFormSaveCoordinator.save(
                context: context,
                request: .init(
                    type: type,
                    recipe: recipe,
                    draft: draft,
                    requestReview: photos.isNotEmpty
                        || CookleImagePlayground.isSupported == false
                ),
                recipeActionService: recipeActionService
            )

            switch result {
            case .created(let createdRecipe):
                savedRecipe = createdRecipe
                if createdRecipe.photos?.isEmpty == true,
                   CookleImagePlayground.isSupported {
                    clearSnapshot()
                    isPhotoConfirmationPresented = true
                    return false
                }
                clearSnapshot()
                return true
            case .updated:
                clearSnapshot()
                return true
            }
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

extension RecipeFormModel {
    func activateSnapshotPersistence(
        recipe: Recipe?
    ) {
        snapshotKey = RecipeFormSnapshot.key(
            for: type,
            recipe: recipe
        )
        isSnapshotPersistenceEnabled = true
        refreshSnapshotAvailability()
    }

    func restoreSnapshot() {
        guard let snapshotKey,
              let snapshot = snapshotStore.snapshot(
                for: snapshotKey
              ) else {
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
