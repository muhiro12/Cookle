import Foundation

extension RecipeService {
    private enum InferenceConstants {
        static let minimumMeaningfulMetadataScore = 3
    }

    static let ingredientSectionHeadings = [
        "ingredient",
        "ingredients",
        "material",
        "materials",
        "材料"
    ]

    static let stepSectionHeadings = [
        "direction",
        "directions",
        "instruction",
        "instructions",
        "method",
        "preparation",
        "step",
        "steps",
        "作り方",
        "手順",
        "方法"
    ]

    static let allSectionHeadings = ingredientSectionHeadings + stepSectionHeadings

    /// Serving counts the fallback reads: `Serves 4`, `4 servings`, `4人分`,
    /// `4人前`, and `for 4`, except where `for` starts a duration or a
    /// temperature such as `for 8 minutes` or `for 10-15 minutes`.
    static let fallbackServingSizePattern = #"""
        (?ix)
        serves \s* [:：]? \s* \d+
        | for \s* \d+ (?!\d)
        (?! \s* (?: (?: [-–—~〜～] | to | or ) \s* \d+ \s* )?
        (?: min | hour | hr | sec | ° | degree ) )
        | \d+ \s* (?: servings? | people | persons? | 人分 | 人前 )
        """#

    /// Reads literal minutes after removing ambiguous values; "mint" is not a unit.
    static let fallbackCookingTimePattern = #"(?i)\d+\s*(?:minutes?|mins?)\b|\d+\s*分"#

    static let ambiguousCookingTimePattern = #"""
        (?ix)
        \d+ \s* (?: (?: minutes? \b | mins? \b | 分 ) \s* )?
        (?: [-–—~〜～] | to | or | hours? | hrs? | 時間 | / | [.,] ) \s*
        \d+ \s* (?: minutes? \b | mins? \b | 分 )
        | \d+ \s* 分 \s* の \s* \d+
        """#

    /// Trims user-provided text before recipe inference.
    static func normalizedInferenceInput(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Removes empty entries and normalizes whitespace in inference output.
    static func sanitizedInference(
        _ inference: RecipeInferenceResult
    ) -> RecipeInferenceResult {
        let result: RecipeInferenceResult = .init(
            name: sanitizedInferenceLine(inference.name),
            servingSize: max(inference.servingSize, .zero),
            cookingTime: max(inference.cookingTime, .zero),
            ingredients: inference.ingredients.compactMap { inferredIngredient in
                let ingredient = sanitizedInferenceLine(
                    inferredIngredient.ingredient
                )
                guard !ingredient.isEmpty else {
                    return nil
                }
                return .init(
                    ingredient: ingredient,
                    amount: sanitizedInferenceLine(
                        inferredIngredient.amount
                    )
                )
            },
            steps: inference.steps.compactMap { step in
                let normalizedStep = sanitizedInferenceLine(step)
                return !normalizedStep.isEmpty ? normalizedStep : nil
            },
            categories: inference.categories.compactMap { category in
                let normalizedCategory = sanitizedInferenceLine(category)
                return !normalizedCategory.isEmpty ? normalizedCategory : nil
            },
            note: sanitizedInferenceLine(inference.note)
        )
        return RecipeInferenceNormalization.applying(to: result)
    }

    static func groundedInference(
        _ inference: RecipeInferenceResult,
        sourceText: String
    ) -> RecipeInferenceResult {
        var result = sanitizedInference(inference)
        if let servingRange = explicitServingRange(in: sourceText) {
            result.servingSize = .zero
            result.note = noteRetaining(servingRange, in: result.note)
        }
        if let cookingTimeRange = explicitCookingTimeRange(in: sourceText) {
            result.cookingTime = .zero
            result.note = noteRetaining(cookingTimeRange, in: result.note)
        }
        return result
    }

    /// Appends a stated source fact the numeric field cannot hold, once.
    static func noteRetaining(
        _ sourceFact: String,
        in note: String
    ) -> String {
        guard note.contains(sourceFact) == false else {
            return note
        }
        return [note, sourceFact]
            .filter { value in
                value.isEmpty == false
            }
            .joined(separator: "\n\n")
    }

    /// Returns whether inference output contains enough data to create a recipe.
    static func isMeaningfulInference(
        _ inference: RecipeInferenceResult
    ) -> Bool {
        if !inference.ingredients.isEmpty || !inference.steps.isEmpty {
            return true
        }

        let metadataScore = [
            !inference.name.isEmpty,
            inference.servingSize > .zero,
            inference.cookingTime > .zero,
            !inference.categories.isEmpty,
            !inference.note.isEmpty
        ].filter(\.self).count
        return metadataScore >= InferenceConstants.minimumMeaningfulMetadataScore
    }

    static func sanitizedInferenceLine(
        _ value: String
    ) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            return ""
        }
        return RecipeBlurbService.collapsedWhitespace(trimmedValue)
    }

    static func explicitServingRange(in text: String) -> String? {
        let pattern = #/
                (?ix)
                (?:
                serves \s* [:：]? \s*
                [0-9０-９]+ \s* [-–—〜～~] \s* [0-9０-９]+
                (?: \s* (?: people | persons? ) )?
                |
                [0-9０-９]+ \s* [-–—〜～~] \s* [0-9０-９]+ \s*
                (?: 人分 | 人前 | servings? | people | persons? )
                )
                /#
        guard let match = text.firstMatch(of: pattern) else {
            return nil
        }
        return String(match.output)
    }

    /// Returns a labeled cooking time stated as a range, such as
    /// `Cook time: 20-30 minutes` or `調理時間 20〜30分`.
    ///
    /// Only the labeled form counts: a step such as `simmer 10-15 minutes`
    /// describes one step, not the recipe's cooking time.
    static func explicitCookingTimeRange(in text: String) -> String? {
        let pattern = #/
                (?ix)
                (?: cook (?: ing )? \s* time | 調理時間 )
                \s* [:：]? \s* (?: 約 | about \s* )?
                [0-9０-９]+ \s* (?: [-–—〜～~] | to ) \s* [0-9０-９]+ \s*
                (?: minutes? | mins? | 分 )
                /#
        guard let match = text.firstMatch(of: pattern) else {
            return nil
        }
        return String(match.output)
    }

    /// Extracts basic recipe fields with deterministic local parsing.
    static func fallbackInference(from text: String) -> RecipeInferenceResult {
        let lines = text.components(separatedBy: .newlines)
        let ingredients = fallbackSectionItems(
            from: lines,
            headings: ingredientSectionHeadings
        ).map { ingredient in
            RecipeInferenceIngredient(
                ingredient: ingredient,
                amount: ""
            )
        }
        let steps = fallbackSectionItems(
            from: lines,
            headings: stepSectionHeadings
        )
        let sourceText = halfwidthDigits(
            in: lines.joined(separator: " ")
        )

        return .init(
            name: fallbackName(from: lines),
            servingSize: extractedNumber(
                in: sourceText,
                pattern: fallbackServingSizePattern
            ),
            cookingTime: extractedNumber(
                in: sourceText.replacingOccurrences(
                    of: ambiguousCookingTimePattern,
                    with: " ",
                    options: .regularExpression
                ),
                pattern: fallbackCookingTimePattern
            ),
            ingredients: ingredients,
            steps: steps,
            categories: [],
            note: ""
        )
    }

    static func fallbackName(from lines: [String]) -> String {
        for line in lines {
            let normalizedLine = sanitizedInferenceLine(
                RecipeBlurbService.strippingListPrefix(
                    from: line
                )
            )
            guard !normalizedLine.isEmpty else {
                continue
            }
            guard matchesSectionHeading(
                normalizedLine,
                headings: allSectionHeadings
            ) == false else {
                continue
            }
            return normalizedLine
        }
        return ""
    }

    static func fallbackSectionItems(
        from lines: [String],
        headings: [String]
    ) -> [String] {
        var collectedItems = [String]()
        var isCollecting = false

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else {
                continue
            }

            if let inlineItem = inlineSectionItem(
                from: trimmedLine,
                headings: headings
            ) {
                isCollecting = true
                let normalizedItem = sanitizedInferenceLine(
                    RecipeBlurbService.strippingListPrefix(
                        from: inlineItem
                    )
                )
                if !normalizedItem.isEmpty {
                    collectedItems.append(normalizedItem)
                }
                continue
            }

            if matchesSectionHeading(
                trimmedLine,
                headings: allSectionHeadings
            ) {
                if isCollecting {
                    break
                }
                continue
            }

            guard isCollecting else {
                continue
            }

            let normalizedItem = sanitizedInferenceLine(
                RecipeBlurbService.strippingListPrefix(
                    from: trimmedLine
                )
            )
            if !normalizedItem.isEmpty {
                collectedItems.append(normalizedItem)
            }
        }

        return collectedItems
    }

    static func inlineSectionItem(
        from line: String,
        headings: [String]
    ) -> String? {
        let separators = [":", "："]

        for separator in separators {
            guard let separatorRange = line.range(of: separator) else {
                continue
            }

            let heading = String(line[..<separatorRange.lowerBound])
            guard matchesSectionHeading(
                heading,
                headings: headings
            ) else {
                continue
            }

            return String(line[separatorRange.upperBound...])
        }

        guard matchesSectionHeading(
            line,
            headings: headings
        ) else {
            return nil
        }
        return ""
    }

    static func matchesSectionHeading(
        _ value: String,
        headings: [String]
    ) -> Bool {
        let normalizedValue = normalizedHeading(value)
        return headings.contains(normalizedValue)
    }

    static func normalizedHeading(
        _ value: String
    ) -> String {
        let trimmedValue = RecipeBlurbService.strippingListPrefix(
            from: value
        )
        let trimmedPunctuation = trimmedValue.trimmingCharacters(
            in: CharacterSet.punctuationCharacters.union(
                .whitespacesAndNewlines
            )
        )
        return RecipeBlurbService.collapsedWhitespace(
            trimmedPunctuation
        )
        .replacingOccurrences(of: " ", with: "")
        .lowercased()
    }

    /// Replaces full-width digits, common in Japanese text, with ASCII digits.
    static func halfwidthDigits(
        in value: String
    ) -> String {
        let fullwidthDigits: ClosedRange<Unicode.Scalar> = "０"..."９"
        let fullwidthOffset = fullwidthDigits.lowerBound.value - ("0" as Unicode.Scalar).value
        var scalars = String.UnicodeScalarView()
        for scalar in value.unicodeScalars {
            if fullwidthDigits.contains(scalar),
               let halfwidthScalar = Unicode.Scalar(scalar.value - fullwidthOffset) {
                scalars.append(halfwidthScalar)
            } else {
                scalars.append(scalar)
            }
        }
        return String(scalars)
    }

    static func extractedNumber(
        in sourceText: String,
        pattern: String
    ) -> Int {
        guard let match = sourceText.range(
            of: pattern,
            options: .regularExpression
        ) else {
            return .zero
        }
        let matchedText = String(sourceText[match])
        let digits = matchedText
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
        return Int(digits) ?? .zero
    }
}
