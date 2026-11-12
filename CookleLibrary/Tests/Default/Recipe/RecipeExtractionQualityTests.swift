import CookleLibrary
import Testing

/// Synthetic field-correction cases; these exercise production fallback and grounding, not model quality.
@MainActor
struct RecipeExtractionQualityTests {
    struct Example: Sendable {
        let identifier: String
        let text: String
        let name: String
        let servings: Int
        let minutes: Int
        let ingredients: [RecipeInferenceIngredient]
        let steps: [String]
        let notes: [String]
    }

    nonisolated static let cases: [Example] = [
        .init(
            identifier: "english_labeled",
            text: """
                Bean Salad
                Servings: 2
                Cooking Time: 10 minutes
                Ingredients:
                Beans: 100 g
                Carrot: 1
                Steps:
                Slice the carrot.
                Mix with the beans.
                Notes:
                Synthetic recipe for evaluation.
                Source: https://example.com/bean-salad
                """,
            name: "Bean Salad",
            servings: 2,
            minutes: 10,
            ingredients: [
                .init(ingredient: "Beans", amount: "100 g"),
                .init(ingredient: "Carrot", amount: "1")
            ],
            steps: [
                "Slice the carrot.",
                "Mix with the beans."
            ],
            notes: ["Synthetic recipe for evaluation.", "https://example.com/bean-salad"]
        ),
        .init(
            identifier: "japanese_markdown",
            text: """
                # 豆の和え物
                2人分
                調理時間: 5分
                ## 材料
                - 豆：100 g
                - にんじん：1/2本
                - 塩：少々
                ## 手順
                1. にんじんを薄く切る。
                2. 豆とにんじんを混ぜる。
                ## メモ
                冷たいまま提供する。
                出典: https://example.com/beans
                """,
            name: "豆の和え物",
            servings: 2,
            minutes: 5,
            ingredients: [
                .init(ingredient: "豆", amount: "100 g"),
                .init(ingredient: "にんじん", amount: "1/2本"),
                .init(ingredient: "塩", amount: "少々")
            ],
            steps: [
                "にんじんを薄く切る。",
                "豆とにんじんを混ぜる。"
            ],
            notes: ["冷たいまま提供する。", "https://example.com/beans"]
        ),
        .init(
            identifier: "rendered_quantities",
            text: """
                Warm Bean Bowl
                Serves 2
                Ingredients
                Beans 100 g
                Water 200 ml
                Salt a pinch
                Steps
                1. Add beans and water.
                2. Simmer for 8 minutes.
                3. Serve.
                """,
            name: "Warm Bean Bowl",
            servings: 2,
            minutes: 0,
            ingredients: [
                .init(ingredient: "Beans", amount: "100 g"),
                .init(ingredient: "Water", amount: "200 ml"),
                .init(ingredient: "Salt", amount: "a pinch")
            ],
            steps: [
                "Add beans and water.",
                "Simmer for 8 minutes.",
                "Serve."
            ],
            notes: []
        ),
        .init(
            identifier: "ambiguous",
            text: """
                野菜スープ
                2〜3人分
                調理時間: 20〜30分
                材料
                大根: 1/2本
                水: 300 ml
                塩: 適量
                手順
                大根を切る。
                水を加えて煮る。
                """,
            name: "野菜スープ",
            servings: 0,
            minutes: 0,
            ingredients: [
                .init(ingredient: "大根", amount: "1/2本"),
                .init(ingredient: "水", amount: "300 ml"),
                .init(ingredient: "塩", amount: "適量")
            ],
            steps: [
                "大根を切る。",
                "水を加えて煮る。"
            ],
            notes: ["2〜3人分", "調理時間: 20〜30分"]
        ),
        .init(
            identifier: "markdown_table",
            text: """
                # Simple Rice Bowl
                Serves 2
                ## Ingredients
                | Ingredient | Amount |
                | --- | --- |
                | Rice | 150 g |
                | Beans | 100 g |
                ## Steps
                1. Cook the rice.
                2. Add the beans.
                """,
            name: "Simple Rice Bowl",
            servings: 2,
            minutes: 0,
            ingredients: [
                .init(ingredient: "Rice", amount: "150 g"),
                .init(ingredient: "Beans", amount: "100 g")
            ],
            steps: [
                "Cook the rice.",
                "Add the beans."
            ],
            notes: []
        ),
        .init(
            identifier: "step_continuation",
            text: """
                Sample Stew
                Ingredients:
                Onion: 1
                Water: 200 ml
                Steps:
                1. Cut the onion.
                   Keep the pieces the same size.
                2. Add water.
                   Do not cover the pot.
                Notes:
                Use a small pot.
                """,
            name: "Sample Stew",
            servings: 0,
            minutes: 0,
            ingredients: [
                .init(ingredient: "Onion", amount: "1"),
                .init(ingredient: "Water", amount: "200 ml")
            ],
            steps: [
                "Cut the onion. Keep the pieces the same size.",
                "Add water. Do not cover the pot."
            ],
            notes: ["Use a small pot."]
        ),
        .init(
            identifier: "french",
            text: """
                Salade de haricots
                Ingrédients:
                Haricots: 100 g
                Carotte: 1
                Étapes:
                Couper la carotte.
                Mélanger avec les haricots.
                """,
            name: "Salade de haricots",
            servings: 0,
            minutes: 0,
            ingredients: [
                .init(ingredient: "Haricots", amount: "100 g"),
                .init(ingredient: "Carotte", amount: "1")
            ],
            steps: [
                "Couper la carotte.",
                "Mélanger avec les haricots."
            ],
            notes: []
        )
    ]

    @Test(arguments: cases)
    func explicit_recipe_facts_need_no_field_corrections(example: Example) {
        let result = RecipeInferenceOperations.groundedInference(
            RecipeInferenceOperations.fallbackInference(from: example.text),
            sourceText: example.text
        )
        #expect(result.name == example.name)
        #expect(result.servingSize == example.servings)
        #expect(result.cookingTime == example.minutes)
        #expect(result.ingredients == example.ingredients)
        #expect(result.steps == example.steps)
        #expect(result.categories.isEmpty)
        for note in example.notes {
            #expect(result.note.contains(note))
        }
    }
}
