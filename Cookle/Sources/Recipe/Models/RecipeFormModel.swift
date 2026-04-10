import MHPlatform
import Observation
import SwiftData

@MainActor
@Observable
final class RecipeFormModel {
    let type: RecipeFormType

    var name = ""
    var photos = [PhotoData]()
    var servingSize = ""
    var cookingTime = ""
    var ingredients = [RecipeFormIngredient]()
    var steps = [String]()
    var categories = [String]()
    var note = ""

    var errorMessage: String?
    var savedRecipe: Recipe?
    var isPhotoConfirmationPresented = false
    var isImagePlaygroundPresented = false
    var isInferRecipeFromTextTipEligible = false
    var isImagePlaygroundTipEligible = false

    private var hasAppliedRecipe = false

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

    init(type: RecipeFormType) {
        self.type = type
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
                    isPhotoConfirmationPresented = true
                    return false
                }
                return true
            case .updated:
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
