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
