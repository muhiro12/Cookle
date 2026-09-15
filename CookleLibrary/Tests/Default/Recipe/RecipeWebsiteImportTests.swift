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
}
