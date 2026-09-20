@testable import CookleLibrary
import SwiftData
import Testing

/// Pins which tag values `TagService.duplicateTags` treats as the same tag.
///
/// Merging is destructive, so both directions matter: a variant that should be
/// offered for merging, and a value that must never be swept into one.
@MainActor
struct TagDuplicateNormalizationTests {
    let context: ModelContext = makeTestContext()

    @Test
    func duplicateTags_matches_case_width_diacritic_and_spacing_variants() {
        let equivalentPairs = [
            ("Eggs", "eggs"),
            ("  Eggs  ", "Eggs"),
            ("Olive  Oil", "olive oil"),
            ("Crème", "creme"),
            ("ＴＯＭＡＴＯ", "tomato"),
            ("ﾄﾏﾄ", "トマト")
        ]

        for (storedValue, variantValue) in equivalentPairs {
            let stored = makeIngredient(value: storedValue)
            let variant = makeIngredient(value: variantValue)

            let duplicates = TagService.duplicateTags(
                matching: stored,
                in: [stored, variant]
            )

            #expect(
                duplicates.count == 2,
                "\(storedValue) and \(variantValue) should look like the same tag"
            )
        }
    }

    @Test
    func duplicateTags_keeps_distinct_values_separate() {
        let distinctPairs = [
            ("Eggs", "Egg"),
            ("Olive Oil", "Olive"),
            // Hiragana and katakana fold to different keys, so a Japanese
            // ingredient typed in either script is never merged into the other.
            ("とまと", "トマト")
        ]

        for (storedValue, otherValue) in distinctPairs {
            let stored = makeIngredient(value: storedValue)
            let other = makeIngredient(value: otherValue)

            let duplicates = TagService.duplicateTags(
                matching: stored,
                in: [stored, other]
            )

            #expect(
                duplicates.map(\.value) == [storedValue],
                "\(storedValue) must not absorb \(otherValue)"
            )
        }
    }

    @Test
    func duplicateTags_does_not_match_half_width_kana_carrying_a_voicing_mark() {
        // Width folding widens the base kana but leaves a half-width dakuten or
        // handakuten as a character of its own, so `ﾆﾝｼﾞﾝ` folds to `ニンシﾞン`
        // rather than `ニンジン`. Half-width katakana therefore reaches its
        // full-width form only while it stays unvoiced, as `ﾄﾏﾄ` above does.
        //
        // Voiced kana is common in Japanese ingredient names, so this is the
        // normalization gap a Japanese-first store actually runs into.
        let unmatchedPairs = [
            ("ﾆﾝｼﾞﾝ", "ニンジン"),
            ("ﾀﾏﾈｷﾞ", "タマネギ"),
            ("ﾊﾟﾝ", "パン")
        ]

        for (halfWidthValue, fullWidthValue) in unmatchedPairs {
            let halfWidth = makeIngredient(value: halfWidthValue)
            let fullWidth = makeIngredient(value: fullWidthValue)

            let duplicates = TagService.duplicateTags(
                matching: halfWidth,
                in: [halfWidth, fullWidth]
            )

            #expect(
                duplicates.map(\.value) == [halfWidthValue],
                "\(halfWidthValue) and \(fullWidthValue) are not grouped today"
            )
        }
    }

    @Test
    func duplicateTags_groups_only_values_that_repeat() {
        let first = makeIngredient(value: "Eggs")
        let second = makeIngredient(value: "eggs")
        let unique = makeIngredient(value: "Flour")

        let groups = TagService.duplicateTags(
            in: [first, second, unique]
        )

        // Exactly one group is reported, and the unique value is left alone.
        // Which spelling represents the group is decided by
        // `localizedStandardCompare`, so it is locale-sensitive and deliberately
        // not pinned here.
        #expect(groups.count == 1)
        #expect(["Eggs", "eggs"].contains(groups.first?.value ?? ""))
    }
}

private extension TagDuplicateNormalizationTests {
    func makeIngredient(value: String) -> Ingredient {
        Ingredient.restore(
            context: context,
            value: value,
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
    }
}
