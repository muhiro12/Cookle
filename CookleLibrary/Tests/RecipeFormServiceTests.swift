@testable import CookleLibrary
import SwiftData
import Testing

@MainActor
struct RecipeFormServiceTests {
    let context: ModelContext = makeTestContext()

    @Test
    func makeDraft_converts_fullwidth_numbers() throws {
        let draft = try RecipeFormService.makeDraft(
            name: "Pancakes",
            photos: [],
            servingSize: "１２",
            cookingTime: "４５",
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )

        #expect(draft.servingSize == 12)
        #expect(draft.cookingTime == 45)
    }

    @Test
    func makeDraft_removes_empty_rows_but_preserves_order() throws {
        let draft = try RecipeFormService.makeDraft(
            name: "Pancakes",
            photos: [],
            servingSize: "2",
            cookingTime: "10",
            ingredients: [
                .init(ingredient: "", amount: ""),
                .init(ingredient: "Flour", amount: "100g"),
                .init(ingredient: "", amount: "ignored"),
                .init(ingredient: "Milk", amount: "200ml")
            ],
            steps: [
                "Step 1",
                "",
                "Step 2"
            ],
            categories: [
                "",
                "Breakfast"
            ],
            note: "note"
        )

        #expect(draft.ingredients.map(\.ingredient) == ["Flour", "Milk"])
        #expect(draft.ingredients.map(\.amount) == ["100g", "200ml"])
        #expect(draft.steps == ["Step 1", "Step 2"])
        #expect(draft.categories == ["Breakfast"])
    }

    @Test
    func create_and_update_keep_order_and_refresh_modified_timestamp() throws {
        let createDraft = try RecipeFormService.makeDraft(
            name: "Pancakes",
            photos: [],
            servingSize: "1",
            cookingTime: "10",
            ingredients: [
                .init(ingredient: "Flour", amount: "100g"),
                .init(ingredient: "Milk", amount: "200ml")
            ],
            steps: ["mix", "cook"],
            categories: ["Breakfast"],
            note: "first"
        )
        let recipe = RecipeFormService.create(
            context: context,
            draft: createDraft
        )
        let firstIngredientValues = recipe.ingredientObjects?.sorted().compactMap {
            $0.ingredient?.value
        } ?? []
        #expect(firstIngredientValues == ["Flour", "Milk"])

        let originalModifiedTimestamp = recipe.modifiedTimestamp
        let updateDraft = try RecipeFormService.makeDraft(
            name: "Updated Pancakes",
            photos: [],
            servingSize: "2",
            cookingTime: "15",
            ingredients: [
                .init(ingredient: "Egg", amount: "1"),
                .init(ingredient: "Butter", amount: "10g")
            ],
            steps: ["mix", "cook", "serve"],
            categories: ["Brunch"],
            note: "updated"
        )
        RecipeFormService.update(
            context: context,
            recipe: recipe,
            draft: updateDraft
        )

        let updatedIngredientValues = recipe.ingredientObjects?.sorted().compactMap {
            $0.ingredient?.value
        } ?? []
        #expect(updatedIngredientValues == ["Egg", "Butter"])
        #expect(recipe.modifiedTimestamp >= originalModifiedTimestamp)
        #expect(recipe.name == "Updated Pancakes")
    }

    @Test
    func makeDraft_throws_validation_error_for_invalid_values() {
        #expect(throws: RecipeFormValidationError.emptyName) {
            _ = try RecipeFormService.makeDraft(
                name: "",
                photos: [],
                servingSize: "1",
                cookingTime: "1",
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        }

        #expect(throws: RecipeFormValidationError.invalidServingSize("abc")) {
            _ = try RecipeFormService.makeDraft(
                name: "Recipe",
                photos: [],
                servingSize: "abc",
                cookingTime: "1",
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        }
    }
}
