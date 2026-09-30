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

    @Test(
        arguments: [
            "Boil the pasta for 8 minutes.",
            "Bake for 10-15 minutes.",
            "Simmer for 2 to 3 minutes.",
            "Roast for 1 hour.",
            "Bake for 180°C."
        ]
    )
    func a_duration_or_temperature_after_for_is_not_a_serving_count(
        step: String
    ) {
        let result = RecipeInferenceOperations.fallbackInference(
            from: """
            Pasta
            Ingredients:
            Pasta 200g
            Steps:
            \(step)
            """
        )

        // `for 8` used to become eight servings. Unknown stays zero instead of
        // turning a step's duration into an invented count.
        #expect(result.servingSize == .zero)
    }

    @Test(
        arguments: [
            ("Pasta for 2", 2),
            ("Stew for 4 people", 4),
            ("Curry, 6 servings", 6),
            ("カレー 4人前", 4),
            ("シチュー ４人分", 4)
        ]
    )
    func explicit_serving_counts_are_read(
        title: String,
        servingSize: Int
    ) {
        let result = RecipeInferenceOperations.fallbackInference(
            from: """
            \(title)
            Ingredients:
            Rice 1 cup
            Steps:
            Cook.
            """
        )

        // Full-width digits, common in Japanese text, read like ASCII ones.
        #expect(result.servingSize == servingSize)
    }

    @Test(
        arguments: [
            ("約３０分煮込む。", 30),
            ("玉ねぎ 2分の1個を加える。", 0),
            ("1時間30分煮込む。", 0),
            ("1時間 30分煮込む。", 0),
            ("1時間  30分煮込む。", 0),
            ("玉ねぎ 2分 の 1個を加える。", 0),
            ("Add 5 mint leaves.", 0),
            ("Wait 1 hour  30 minutes.", 0),
            ("Stir for 1/2 minute.", 0),
            ("Wait 1.5 minutes.", 0),
            ("Wait 1,5 minutes.", 0),
            ("1.5分待つ。", 0)
        ]
    )
    func literal_minutes_are_read_but_ambiguous_units_stay_unknown(
        step: String,
        cookingTime: Int
    ) {
        let result = RecipeInferenceOperations.fallbackInference(
            from: """
            煮込み
            材料
            牛肉 300g
            手順
            \(step)
            """
        )

        // 「2分の1」 is a half, not two minutes, and the 30 of 「1時間30分」
        // is not the whole duration. Neither is read.
        #expect(result.cookingTime == cookingTime)
    }

    @Test(
        arguments: [
            "Simmer 20-30 minutes.",
            "Simmer for 2 to 3 minutes.",
            "20〜30分煮る。",
            "２０～３０分煮る。",
            "Simmer 20 -  30 minutes.",
            "Simmer 20 to  30 minutes.",
            "Simmer 20 or 30 minutes.",
            "20 〜  30分煮る。",
            "Simmer 20 min to 30 min.",
            "20分〜30分煮る。"
        ]
    )
    func a_duration_range_is_not_read_as_either_end(
        step: String
    ) {
        let result = RecipeInferenceOperations.fallbackInference(
            from: """
            Soup
            Ingredients:
            Onion 1
            Steps:
            \(step)
            """
        )

        // Picking 20 or 30 would state a precision the source does not have.
        #expect(result.cookingTime == .zero)
    }

    @Test
    func a_japanese_serving_range_from_the_fallback_becomes_unknown() {
        let sourceText = """
            煮物
            2〜3人分
            材料
            大根 1/2本
            手順
            煮る。
            """
        let result = RecipeInferenceOperations.groundedInference(
            RecipeInferenceOperations.fallbackInference(
                from: sourceText
            ),
            sourceText: sourceText
        )

        // The fallback reads 「3人分」 inside the range; grounding then resets
        // the count and keeps the stated range in the note, as it does for
        // model output.
        #expect(result.servingSize == .zero)
        #expect(result.note.contains("2〜3人分"))
    }
}
