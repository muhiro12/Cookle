@testable import CookleLibrary
import Foundation
import Testing

@MainActor
struct MutationEffectPropagationTests {
    let context = makeTestContext()

    @Test
    func recipeFormMutationsReturnRecipeAndNotificationEffects() throws {
        let createDraft = try RecipeFormService.makeDraft(
            name: "Pasta",
            photos: [],
            servingSize: "2",
            cookingTime: "15",
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )

        let createOutcome = RecipeFormService.createWithOutcome(
            context: context,
            draft: createDraft
        )

        #expect(createOutcome.effects.contains(.recipeDataChanged))
        #expect(createOutcome.effects.contains(.notificationPlanChanged))
        #expect(createOutcome.effects.contains(.reviewPromptEligible) == false)

        let updateDraft = try RecipeFormService.makeDraft(
            name: "Updated Pasta",
            photos: [],
            servingSize: "4",
            cookingTime: "20",
            ingredients: [],
            steps: [],
            categories: [],
            note: "Updated"
        )

        let updateOutcome = RecipeFormService.updateWithOutcome(
            context: context,
            recipe: createOutcome.value,
            draft: updateDraft
        )

        #expect(updateOutcome.effects.contains(.recipeDataChanged))
        #expect(updateOutcome.effects.contains(.notificationPlanChanged))
    }

    @Test
    func recipeDeletionAndLastOpenedTrackingReturnExpectedEffects() {
        let recipe = Recipe.create(
            context: context,
            name: "Toast",
            photos: [],
            servingSize: 1,
            cookingTime: 5,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )

        let lastOpenedOutcome = RecipeService.recordLastOpenedRecipeWithOutcome(
            recipe
        )
        let deleteOutcome = RecipeService.deleteWithOutcome(
            context: context,
            recipe: recipe
        )

        #expect(lastOpenedOutcome.effects == [.recipeDataChanged])
        #expect(deleteOutcome.effects.contains(.recipeDataChanged))
        #expect(deleteOutcome.effects.contains(.notificationPlanChanged))
    }

    @Test
    func diaryMutationsReturnDiaryEffectHint() throws {
        let recipe = Recipe.create(
            context: context,
            name: "Soup",
            photos: [],
            servingSize: 2,
            cookingTime: 30,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )

        let createOutcome = DiaryService.createWithOutcome(
            context: context,
            date: .now,
            breakfasts: [recipe],
            lunches: [],
            dinners: [],
            note: ""
        )
        let addOutcome = try DiaryService.addWithOutcome(
            context: context,
            date: .now,
            recipe: recipe,
            type: .dinner
        )
        let deleteOutcome = DiaryService.deleteWithOutcome(
            context: context,
            diary: createOutcome.value
        )

        #expect(createOutcome.effects == [.diaryDataChanged])
        #expect(addOutcome.effects == [.diaryDataChanged])
        #expect(deleteOutcome.effects == [.diaryDataChanged])
    }

    @Test
    func tagMutationsReturnNotificationPlanningHint() throws {
        let ingredient = Ingredient.create(
            context: context,
            value: "Salt"
        )
        let category = Category.create(
            context: context,
            value: "Dinner"
        )

        let renameOutcome = try TagService.renameWithOutcome(
            context: context,
            ingredient: ingredient,
            value: "Sea Salt"
        )
        let categoryRenameOutcome = try TagService.renameWithOutcome(
            context: context,
            category: category,
            value: "Supper"
        )

        #expect(renameOutcome.effects == [.notificationPlanChanged])
        #expect(categoryRenameOutcome.effects == [.notificationPlanChanged])
    }

    @Test
    func dataResetReturnsAllFollowUpHints() throws {
        _ = Recipe.create(
            context: context,
            name: "Reset Target",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )

        let outcome = try DataResetService.deleteAllWithOutcome(
            context: context
        )

        #expect(outcome.effects.contains(.diaryDataChanged))
        #expect(outcome.effects.contains(.recipeDataChanged))
        #expect(outcome.effects.contains(.notificationPlanChanged))
    }
}
