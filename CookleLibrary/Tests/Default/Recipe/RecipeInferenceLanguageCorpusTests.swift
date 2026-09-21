@testable import CookleLibrary
import Foundation
import Testing

// Where the deterministic extraction path stops understanding its input.
//
// `RecipeInferenceCorpusTests` covers the shape of an extraction. These cover
// the two boundaries that shape hides: which languages the section headings are
// recognised in, and how far a unit is interpreted.
//
// The short version, measured rather than assumed. Heading recognition is
// English and Japanese, and the two can be mixed in one document. Anything else
// yields a name and nothing more, reported as not meaningful. Units are never
// interpreted, normalised, or disambiguated.
@MainActor
struct RecipeInferenceLanguageCorpusTests {
    @Test
    func ambiguous_units_are_carried_verbatim_and_never_interpreted() {
        let result = RecipeInferenceOperations.fallbackInference(
            from: """
            Spice Mix
            Ingredients:
            Cumin 2 T
            Salt 2 t
            Flour 1 c
            Water 200
            Steps:
            Mix.
            """
        )

        // `T` and `t` could each be tablespoon or teaspoon, `c` could be cup,
        // and the last line has no unit at all. None of that is resolved,
        // normalised, or guessed here; the line is kept as the source wrote it.
        #expect(
            result.ingredients.map(\.ingredient) == [
                "Cumin 2 T",
                "Salt 2 t",
                "Flour 1 c",
                "Water 200"
            ]
        )
        let everyAmountIsEmpty = result.ingredients.allSatisfy(\.amount.isEmpty)
        #expect(everyAmountIsEmpty)
    }

    @Test
    func a_language_without_recognised_headings_yields_only_a_name() {
        let result = RecipeInferenceOperations.fallbackInference(
            from: """
            김치찌개
            재료
            김치 300g
            두부 1모
            조리법
            김치를 볶는다.
            물을 붓는다.
            """
        )

        // This is the boundary the Japanese case above can hide: heading
        // recognition is English and Japanese, not "any language". Korean
        // 재료 / 조리법 are not headings here, so every ingredient and step is
        // dropped and the whole result is reported as not meaningful — which
        // is what routes the user back to the model or to manual entry rather
        // than to a half-filled form.
        #expect(result.name == "김치찌개")
        #expect(result.ingredients.isEmpty)
        #expect(result.steps.isEmpty)
        #expect(RecipeInferenceOperations.isMeaningfulInference(result) == false)
    }

    @Test
    func input_without_any_headings_yields_only_a_name() {
        let result = RecipeInferenceOperations.fallbackInference(
            from: """
            Soupe de Legumes
            Carottes 3
            Pommes de terre 2
            Faire bouillir.
            Servir chaud.
            """
        )

        // The dependency is on the headings, not on the language: English prose
        // laid out without `Ingredients:` and `Steps:` fares the same way.
        #expect(result.name == "Soupe de Legumes")
        #expect(result.ingredients.isEmpty)
        #expect(result.steps.isEmpty)
        #expect(RecipeInferenceOperations.isMeaningfulInference(result) == false)
    }

    @Test
    func headings_in_two_languages_work_in_one_document() {
        let result = RecipeInferenceOperations.fallbackInference(
            from: """
            Chicken Curry
            材料
            Chicken 300g
            玉ねぎ 1個
            Steps:
            Cook the chicken.
            """
        )

        // A Japanese ingredients heading and an English steps heading are both
        // recognised in the same input, and content in either script survives.
        // This is the realistic shape when someone pastes a foreign recipe into
        // a Japanese-language device.
        #expect(result.name == "Chicken Curry")
        #expect(result.ingredients.map(\.ingredient) == ["Chicken 300g", "玉ねぎ 1個"])
        #expect(result.steps == ["Cook the chicken."])
        #expect(RecipeInferenceOperations.isMeaningfulInference(result))
    }

    @Test
    func serves_and_ready_in_are_read_as_a_count_and_a_duration() {
        let result = RecipeInferenceOperations.fallbackInference(
            from: """
            Stew
            Serves 4
            Ready in 45 minutes
            Ingredients:
            Beef 500g
            Steps:
            Simmer.
            """
        )

        // A second English phrasing beyond the one already covered above.
        #expect(result.servingSize == 4)
        #expect(result.cookingTime == 45)
    }
}
