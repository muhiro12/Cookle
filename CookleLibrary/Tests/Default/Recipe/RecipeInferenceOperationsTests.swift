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
}

private extension RecipeInferenceOperationsTests {
    func inference(
        servingSize: Int,
        note: String = ""
    ) -> RecipeInferenceResult {
        .init(
            name: "Soup",
            servingSize: servingSize,
            cookingTime: 0,
            ingredients: [
                .init(ingredient: "Onion", amount: "1")
            ],
            steps: ["Cook."],
            categories: [],
            note: note
        )
    }
}
