import CookleLibrary
import Testing

@MainActor
struct RecipeExtractionBoundaryTests {
    @Test(arguments: [
        "Flour 1 1/2 cups",
        "Milk 2 1/4 cups",
        "Water 1 to 2 cups",
        "Milk 1 or 2 cups",
        "牛乳 １ １/２ cups",
        "Vitamin B12 powder 1 g"
    ])
    func ambiguousTrailingAmountsKeepTheWholeIngredientLine(row: String) {
        let result = extract("Pancakes\nIngredients:\n\(row)\nSteps:\nMix.")

        #expect(result.ingredients == [.init(ingredient: row, amount: "")])
        #expect(result.steps == ["Mix."])
    }

    @Test(arguments: [
        ("Flour 1/2 cup", "Flour", "1/2 cup"),
        ("Milk 1.5 cups", "Milk", "1.5 cups"),
        ("Water 1-2 cups", "Water", "1-2 cups"),
        ("Beans 100 g", "Beans", "100 g"),
        ("Flour: 1 1/2 cups", "Flour", "1 1/2 cups"),
        ("Water: 1 to 2 cups", "Water", "1 to 2 cups"),
        ("Vitamin B12 powder: 1 g", "Vitamin B12 powder", "1 g")
    ])
    func unambiguousAmountsStillSplit(row: String, ingredient: String, amount: String) {
        let result = extract("Recipe\nIngredients:\n\(row)\nSteps:\nMix.")

        #expect(result.ingredients == [.init(ingredient: ingredient, amount: amount)])
    }

    @Test(arguments: [
        "Cooking time will vary with the size of the beans.",
        "Cook time depends on the pan.",
        "Temps de cuisson variable selon la taille des haricots.",
        "Tiempo de cocción variable según el tamaño de las alubias."
    ])
    func cookingTimeProseKeepsEveryFollowingStep(sentence: String) {
        let result = extract("""
            Stew
            Ingredients:
            Beans 100 g
            Steps:
            1. Simmer until tender.
            \(sentence)
            2. Let stand for 10 minutes.
            3. Serve.
            Cooking Time: 20 minutes
            Notes:
            Use a small pot.
            """)

        #expect(result.steps == [
            "Simmer until tender.", sentence, "Let stand for 10 minutes.", "Serve."
        ])
        #expect(result.cookingTime == 20)
        #expect(result.note == "Use a small pot.")
    }

    @Test(arguments: [
        "Cooking Time: 20 minutes",
        "Cook time 20 minutes",
        "Cooking Time about 20 minutes",
        "Cooking Time (minutes): 20",
        "調理時間 約20分"
    ])
    func cookingMetadataStillEndsTheIngredientSection(statement: String) {
        let result = extract("""
            Stew
            Ingredients:
            Beans 100 g
            \(statement)
            Steps:
            Simmer.
            """)

        #expect(result.ingredients == [.init(ingredient: "Beans", amount: "100 g")])
        #expect(result.steps == ["Simmer."])
        #expect(result.cookingTime == 20)
    }

    private func extract(_ text: String) -> RecipeInferenceResult {
        RecipeInferenceOperations.groundedInference(
            RecipeInferenceOperations.fallbackInference(from: text),
            sourceText: text
        )
    }
}
