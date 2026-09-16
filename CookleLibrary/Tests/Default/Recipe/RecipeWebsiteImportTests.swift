@testable import CookleLibrary
import Foundation
import Testing

struct RecipeWebsiteImportTests {
    @Test
    func preserves_sections_quantities_and_non_serving_yield() throws {
        let source = #"""
            {"@graph":[{"@type":"WebPage"},{"@type":["Recipe"],"name":"Buns",
            "recipeYield":"12 buns","recipeIngredient":["Flour 250 g","Salt 1/2 tsp"],
            "recipeInstructions":[{"@type":"HowToSection","name":"Dough","itemListElement":[
            {"@type":"HowToStep","text":"Mix. Rest for 30 minutes."}]},
            {"@type":"HowToStep","text":"Bake at 180°C."}],"tool":"Use the mixing attachment."}]}
        """#
        let text = try RecipeWebsiteImportOperations.sourceText(structuredData: [source], visibleText: "Advertisement")
        #expect(text.contains("Yield (not necessarily servings):\n12 buns"))
        #expect(text.contains("Flour 250 g\nSalt 1/2 tsp"))
        #expect(text.contains("Dough\nMix. Rest for 30 minutes.\nBake at 180°C."))
        #expect(text.contains("Use the mixing attachment."))
        #expect(!text.contains("Advertisement"))
    }

    @Test
    func rejects_multiple_distinct_recipes_but_accepts_duplicate_metadata() throws {
        let first = #"{"@type":"Recipe","name":"Soup"}"#
        let second = #"{"@type":"Recipe","name":"Bread"}"#
        #expect(throws: RecipeWebsiteImportError.multipleRecipes) {
            try RecipeWebsiteImportOperations.sourceText(structuredData: [first, second], visibleText: "")
        }
        let text = try RecipeWebsiteImportOperations.sourceText(structuredData: [first, first], visibleText: "")
        #expect(text == "Name:\nSoup")
    }

    @Test
    func uses_rendered_text_when_metadata_is_missing_or_malformed() throws {
        let text = try RecipeWebsiteImportOperations.sourceText(
            structuredData: ["not json"], visibleText: "  Soup\nUse the paddle.\nCook for 20 minutes.  "
        )
        #expect(text == "Soup\nUse the paddle.\nCook for 20 minutes.")
    }

    @Test
    func rejects_empty_and_oversized_text_without_truncation() {
        #expect(throws: RecipeWebsiteImportError.noContent) {
            try RecipeWebsiteImportOperations.sourceText(structuredData: [], visibleText: " \n ")
        }
        #expect(throws: RecipeWebsiteImportError.contentTooLarge) {
            try RecipeWebsiteImportOperations.sourceText(
                structuredData: [], visibleText: String(repeating: "a", count: 16_001)
            )
        }
    }

    @Test
    func accepts_web_urls_and_rejects_other_schemes_and_credentials() {
        #expect(RecipeWebsiteImportOperations.websiteURL(from: " https://recipes.example/dinner ") != nil)
        for text in ["file:///tmp/recipe", "javascript:alert(1)", "https://user:secret@recipes.example", "soup"] {
            #expect(RecipeWebsiteImportOperations.websiteURL(from: text) == nil)
        }
    }

    @Test
    func source_is_retained_without_changing_an_unrelated_note() throws {
        let url = try #require(URL(string: "https://recipes.example/dinner"))
        #expect(RecipeWebsiteImportOperations.note("My changes", sourceURL: url) == "My changes\n\n\(url)")
        #expect(RecipeWebsiteImportOperations.note("My changes", sourceURL: nil) == "My changes")
    }

    @Test
    func grounding_keeps_group_markers_and_rejects_invented_time_or_servings() throws {
        let source = try RecipeWebsiteImportOperations.source(
            structuredData: [#"""
                {"@type":"Recipe",
                "name":"Soup",
                "author":"Author",
                "recipeYield":"4–6 servings",
                "recipeIngredient":["★Salt 1 tsp"],
                "recipeInstructions":["Mix ★ ingredients."],
                "totalTime":"PT30M"}
            """#],
            visibleText: ""
        )
        let inferred = RecipeInferenceResult(
            name: "Soup",
            servingSize: 4,
            cookingTime: 30,
            ingredients: [.init(ingredient: "Salt", amount: "1 tsp")],
            steps: ["Mix."],
            categories: [],
            note: "An invented endorsement"
        )
        let result = source.grounding(inferred)
        #expect(result.ingredients == [.init(ingredient: "★Salt", amount: "1 tsp")])
        #expect(result.steps == ["Mix ★ ingredients."])
        #expect(result.servingSize == 0)
        #expect(result.cookingTime == 0)
        #expect(result.note.contains("4–6 servings"))
        #expect(result.note.contains("Author"))
        #expect(!result.note.contains("invented"))
    }

    @Test
    func grounding_preserves_correct_splits_and_explicit_cooking_duration() throws {
        let source = try RecipeWebsiteImportOperations.source(
            structuredData: [#"""
                {"@type":"Recipe",
                "recipeYield":"2人分",
                "cookTime":"PT1H15M",
                "recipeIngredient":["Salt 1 tsp"]}
            """#],
            visibleText: ""
        )
        let inferred = RecipeInferenceResult(
            name: "Soup",
            servingSize: 0,
            cookingTime: 0,
            ingredients: [.init(ingredient: "Salt", amount: "1 tsp")],
            steps: [],
            categories: [],
            note: ""
        )
        let result = source.grounding(inferred)
        #expect(result.ingredients == inferred.ingredients)
        #expect(result.servingSize == 2)
        #expect(result.cookingTime == 75)
    }

    @Test
    func grounding_preserves_verified_quantity_first_ingredients() throws {
        let source = try RecipeWebsiteImportOperations.source(
            structuredData: [#"""
                {"@type":"Recipe","recipeIngredient":["3 tbsp olive oil","300g beef mince","50g cheese grated"]}
            """#],
            visibleText: ""
        )
        let inferred = RecipeInferenceResult(
            name: "Pasta",
            servingSize: 0,
            cookingTime: 0,
            ingredients: [
                .init(ingredient: "olive oil", amount: "3 tbsp"),
                .init(ingredient: "beef mince", amount: "300g"),
                .init(ingredient: "cheese", amount: "50g, grated")
            ],
            steps: [],
            categories: [],
            note: ""
        )
        let result = source.grounding(inferred)
        #expect(result.ingredients == [
            .init(ingredient: "olive oil", amount: "3 tbsp"),
            .init(ingredient: "beef mince", amount: "300g"),
            .init(ingredient: "50g cheese grated", amount: "")
        ])
    }

    @Test
    func rendered_ingredient_rows_protect_quantities_without_overriding_other_fields() throws {
        let source = try RecipeWebsiteImportOperations.source(
            structuredData: [],
            visibleText: "Soup",
            knownIngredients: [.init(ingredient: "Potatoes (cut into 4 pieces)", amount: "300g")]
        )
        let inferred = RecipeInferenceResult(
            name: "Soup",
            servingSize: 2,
            cookingTime: 20,
            ingredients: [.init(ingredient: "Potatoes", amount: "4 pieces")],
            steps: ["Cook."],
            categories: [],
            note: ""
        )
        let result = source.grounding(inferred)
        #expect(result.ingredients.first?.ingredient == "Potatoes (cut into 4 pieces)"
        )
        #expect(result.ingredients.first?.amount == "300g")
        #expect(result.cookingTime == 20)
        #expect(result.steps == inferred.steps)
    }
    @Test
    func rendered_steps_and_warnings_survive_model_summarization() throws {
        let steps = ["Put 1 in the pot.", "Select menu 42 → Start. Do not attach the stirring unit."]
        let warning = "Use a heat-resistant bag. Refrigerate and consume within 1–2 days."
        let source = try RecipeWebsiteImportOperations.source(
            structuredData: [],
            visibleText: (steps + [warning]).joined(separator: "\n"),
            knownSteps: steps,
            sourceNotes: [warning]
        )
        let inferred = RecipeInferenceResult(
            name: "Chicken",
            servingSize: 0,
            cookingTime: 0,
            ingredients: [],
            steps: ["Cook the chicken."],
            categories: [],
            note: "Rest before slicing."
        )
        let result = source.grounding(inferred)
        #expect(result.steps == steps)
        #expect(result.note.contains(warning))
        #expect(result.note.contains(inferred.note))
    }

    @Test
    func rendered_warnings_supplement_metadata_and_missing_steps() throws {
        let warning = "Do not leave food in the pot."
        let step = "Select mode 2 → Start."
        for metadata in [
            #"{"@type":"Recipe","name":"Soup"}"#,
            #"{"@type":"Recipe","name":"Soup","recipeInstructions":["Original metadata step."]}"#
        ] {
            let source = try RecipeWebsiteImportOperations.source(
                structuredData: [metadata],
                visibleText: "Page text",
                knownSteps: [step],
                sourceNotes: [warning]
            )
            let inferred = RecipeInferenceResult(
                name: "Soup",
                servingSize: 0,
                cookingTime: 0,
                ingredients: [],
                steps: ["Invented step."],
                categories: [],
                note: "Invented warning."
            )
            let result = source.grounding(inferred)
            #expect(source.text.contains(warning))
            #expect(result.note == warning)
            #expect(result.steps == (metadata.contains("recipeInstructions")
                                        ? ["Original metadata step."] : [step]))
        }
    }

    @Test
    func oversized_rendered_facts_are_rejected_without_truncation() {
        #expect(throws: RecipeWebsiteImportError.contentTooLarge) {
            try RecipeWebsiteImportOperations.source(
                structuredData: [],
                visibleText: "Short page",
                sourceNotes: [String(repeating: "x", count: RecipeWebsiteImportOperations.maximumTextLength + 1)]
            )
        }
    }
}
