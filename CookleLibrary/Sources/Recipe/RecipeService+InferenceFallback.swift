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

    /// Trims user-provided text before recipe inference.
    static func normalizedInferenceInput(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Removes empty entries and normalizes whitespace in inference output.
    static func sanitizedInference(
        _ inference: RecipeInferenceResult
    ) -> RecipeInferenceResult {
        .init(
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
        let sourceText = lines.joined(separator: " ")

        return .init(
            name: fallbackName(from: lines),
            servingSize: extractedNumber(
                in: sourceText,
                pattern: #"(?i)(serves|for)\s*(\d+)"#
            ),
            cookingTime: extractedNumber(
                in: sourceText,
                pattern: #"(?i)(\d+)\s*(min|minutes)"#
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
