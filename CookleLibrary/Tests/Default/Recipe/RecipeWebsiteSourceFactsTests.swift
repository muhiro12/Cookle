import CookleLibrary
import Testing

struct RecipeWebsiteSourceFactsTests {
    @Test
    func visible_serving_labels_resolve_numeric_yield_without_inventing_counts() throws {
        for (metadata, label, count) in [
            ("4.0", "Serves 4", 4), ("4", "4 servings", 4),
            ("4", "Serves 2", 0), ("12 cookies", "Serves 4", 0),
            ("", "4人分", 4), ("", "2〜3人分", 0), ("", "Serves 2-3", 0), ("", "", 0)
        ] {
            let source = try RecipeWebsiteImportOperations.source(
                structuredData: metadata.isEmpty ? [] : ["{\"@type\":\"Recipe\",\"recipeYield\":\"\(metadata)\"}"],
                visibleText: "Soup",
                servingText: label
            )
            let inferred = RecipeInferenceResult(
                name: "Soup", servingSize: 9, cookingTime: 0, ingredients: [], steps: [], categories: [], note: ""
            )
            #expect(source.grounding(inferred).servingSize == count)
            if metadata.isEmpty, count == 0, !label.isEmpty {
                #expect(source.grounding(inferred).note.contains(label))
            }
        }
    }

    @Test
    func website_notes_keep_source_excerpts_without_duplicates_or_unsupported_text() throws {
        let source = try RecipeWebsiteImportOperations.source(
            structuredData: [],
            visibleText: "Soup\n250 kcal\nKeep refrigerated.",
            sourceNotes: ["Keep refrigerated."]
        )
        for (note, expected) in [
            ("Keep refrigerated.", "Keep refrigerated."),
            ("Add to shopping list", "Keep refrigerated."),
            ("Invented nutrition", "Keep refrigerated."),
            ("250 kcal", "250 kcal\n\nKeep refrigerated.")
        ] {
            let inferred = RecipeInferenceResult(
                name: "Soup", servingSize: 0, cookingTime: 0, ingredients: [], steps: [], categories: [], note: note
            )
            #expect(source.grounding(inferred).note == expected)
        }
    }

    @Test
    func ingredient_splits_preserve_preparation_and_prefer_complete_units() throws {
        let source = try RecipeWebsiteImportOperations.source(
            structuredData: [#"{"@type":"Recipe","recipeIngredient":["1 tbsp oil for frying","100g cheese grated"]}"#],
            visibleText: ""
        )
        let inferred = RecipeInferenceResult(
            name: "Soup",
            servingSize: 0,
            cookingTime: 0,
            ingredients: [
                .init(ingredient: "oil", amount: "1"),
                .init(ingredient: "oil", amount: "1 tbsp"),
                .init(ingredient: "cheese", amount: "10")
            ],
            steps: [],
            categories: [],
            note: ""
        )
        #expect(source.grounding(inferred).ingredients == [
            .init(ingredient: "oil for frying", amount: "1 tbsp"),
            .init(ingredient: "100g cheese grated", amount: "")
        ])
    }
    @Test
    func preparation_moved_into_amount_is_returned_to_original_ingredient_text() throws {
        let source = try RecipeWebsiteImportOperations.source(
            structuredData: [#"""
                {"@type":"Recipe","recipeIngredient":["2 large onions finely chopped",
                "2-3  garlic cloves crushed","50g cheese finely grated"]}
            """#],
            visibleText: ""
        )
        let inferred = RecipeInferenceResult(
            name: "Soup",
            servingSize: 0,
            cookingTime: 0,
            ingredients: [
                .init(ingredient: "onions", amount: "2 large finely chopped"),
                .init(ingredient: "garlic cloves", amount: "2-3 crushed"),
                .init(ingredient: "cheese", amount: "50g finely grated")
            ],
            steps: [],
            categories: [],
            note: ""
        )
        #expect(source.grounding(inferred).ingredients == [
            .init(ingredient: "onions finely chopped", amount: "2 large"),
            .init(ingredient: "garlic cloves crushed", amount: "2-3"),
            .init(ingredient: "cheese finely grated", amount: "50g")
        ])
    }

    @Test
    func website_ingredients_keep_group_meaning_without_polluting_reusable_names() throws {
        let source = try RecipeWebsiteImportOperations.source(
            structuredData: [#"""
                {"@type":"Recipe",
                "recipeIngredient":["[A] 醤油 大さじ1","[A] 砂糖 小さじ1","[B] マヨネーズ 大さじ2","[B] 七味 少々"],
                "recipeInstructions":["Aを加える。","仕上げにBをかける。"]}
            """#],
            visibleText: ""
        )
        let inferred = RecipeInferenceResult(
            name: "たれ",
            servingSize: 0,
            cookingTime: 0,
            ingredients: [
                .init(ingredient: "[A] 醤油", amount: "大さじ1"),
                .init(ingredient: "[A] 砂糖", amount: "小さじ1"),
                .init(ingredient: "[B] マヨネーズ", amount: "大さじ2"),
                .init(ingredient: "[B] 七味", amount: "少々")
            ],
            steps: [],
            categories: ["A", "[B]", "Stew"],
            note: ""
        )

        let result = source.grounding(inferred)

        #expect(result.ingredients.map(\.ingredient) == ["醤油", "砂糖", "マヨネーズ", "七味"])
        #expect(result.steps == ["Aを加える。", "仕上げにBをかける。"])
        #expect(result.note == "A: 醤油, 砂糖\nB: マヨネーズ, 七味")
        #expect(result.categories == ["Stew"])
    }

    @Test
    func website_ingredients_move_preparation_qualifiers_to_amounts() throws {
        let source = try RecipeWebsiteImportOperations.source(
            structuredData: [#"{"@type":"Recipe","recipeIngredient":["人参（角切り） 1/2個"]}"#],
            visibleText: ""
        )
        let inferred = RecipeInferenceResult(
            name: "煮物",
            servingSize: 0,
            cookingTime: 0,
            ingredients: [.init(ingredient: "人参", amount: "1/2個（角切り）")],
            steps: [],
            categories: [],
            note: ""
        )

        #expect(source.grounding(inferred).ingredients == [
            .init(ingredient: "人参", amount: "1/2個（角切り）")
        ])
    }
}
