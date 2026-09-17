@testable import CookleLibrary
import Testing

@MainActor
struct RecipeInferenceOperationsTests {
    @Test(
        arguments: [
            "2〜3人分",
            "２～３人前",
            "2-3 servings",
            "Serves 2–3",
            "Serves: 2—3 people"
        ]
    )
    func grounding_preserves_ambiguous_serving_ranges(
        servingRange: String
    ) {
        let inference = inference(servingSize: 2)

        let result = RecipeInferenceOperations.groundedInference(
            inference,
            sourceText: "Soup\n\(servingRange)\nIngredients\nOnion"
        )

        #expect(result.servingSize == 0)
        #expect(result.note == servingRange)
    }

    @Test
    func grounding_does_not_duplicate_a_retained_serving_range() {
        let servingRange = "2〜3人分"
        let inference = inference(
            servingSize: 2,
            note: "Keep refrigerated.\n\n\(servingRange)"
        )

        let result = RecipeInferenceOperations.groundedInference(
            inference,
            sourceText: "Soup\n\(servingRange)"
        )

        #expect(result.servingSize == 0)
        #expect(result.note == "Keep refrigerated. \(servingRange)")
    }

    @Test
    func grounding_keeps_an_explicit_single_serving_count() {
        let inference = inference(servingSize: 2)

        let result = RecipeInferenceOperations.groundedInference(
            inference,
            sourceText: "Soup\n2 servings"
        )

        #expect(result.servingSize == 2)
        #expect(result.note.isEmpty)
    }

    @Test
    func sanitizing_moves_ingredient_groups_to_the_note() {
        let result = RecipeInferenceOperations.sanitizedInference(
            inference(
                ingredients: [
                    .init(ingredient: "A 醤油", amount: "大さじ1"),
                    .init(ingredient: "A 砂糖", amount: "小さじ1"),
                    .init(ingredient: "B マヨネーズ", amount: "大さじ2"),
                    .init(ingredient: "B 七味", amount: "少々")
                ]
            )
        )

        #expect(result.ingredients.map(\.ingredient) == ["醤油", "砂糖", "マヨネーズ", "七味"])
        #expect(result.note == "A: 醤油, 砂糖\nB: マヨネーズ, 七味")
    }

    @Test
    func sanitizing_moves_preparation_qualifiers_to_the_amount() {
        let result = RecipeInferenceOperations.sanitizedInference(
            inference(
                ingredients: [
                    .init(ingredient: "人参（角切り）", amount: "1/2個"),
                    .init(ingredient: "玉ねぎ (薄切り)", amount: "1個"),
                    .init(ingredient: "ねぎ（小口切り）", amount: "")
                ]
            )
        )

        #expect(result.ingredients == [
            .init(ingredient: "人参", amount: "1/2個（角切り）"),
            .init(ingredient: "玉ねぎ", amount: "1個(薄切り)"),
            .init(ingredient: "ねぎ", amount: "（小口切り）")
        ])
    }
}

private extension RecipeInferenceOperationsTests {
    func inference(
        servingSize: Int = 2,
        note: String = "",
        ingredients: [RecipeInferenceIngredient] = [
            .init(ingredient: "Onion", amount: "1")
        ]
    ) -> RecipeInferenceResult {
        .init(
            name: "Soup",
            servingSize: servingSize,
            cookingTime: 0,
            ingredients: ingredients,
            steps: ["Cook."],
            categories: [],
            note: note
        )
    }
}
