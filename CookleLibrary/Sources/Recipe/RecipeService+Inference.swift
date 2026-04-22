import Foundation
import FoundationModels

@available(iOS 26.0, *)
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

    static var inferenceInstructions: String {
        """
        You extract structured recipe form fields from recipe-like text.
        The text may come from OCR, copied recipe pages, or dictated notes.
        Return only information that is explicit or strongly implied by the input.
        Preserve the input's original language and wording where practical.
        Do not answer as a chef or rewrite the recipe into polished prose.
        Do not invent ingredients, steps, servings, cooking time, categories, or notes.
        Use 0 for unknown numeric values and empty strings or empty arrays for missing text fields.
        """
    }

    /// Infers a recipe structure from free-form text using an LLM and a conservative fallback.
    /// - Parameter text: Free-form user text describing a recipe.
    /// - Returns: An `InferredRecipe` with best-effort fields filled.
    public static func infer(text: String) async throws -> InferredRecipe {
        let normalizedText = normalizedInferenceInput(text)
        guard normalizedText.isNotEmpty else {
            throw RecipeInferenceError.emptyInput
        }

        let fallback = sanitizedInference(
            fallbackInference(from: normalizedText)
        )
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable:
            guard isMeaningfulInference(fallback) else {
                throw RecipeInferenceError.modelUnavailable
            }
            return fallback
        }

        let session = LanguageModelSession(
            instructions: inferenceInstructions
        )

        do {
            let inferred = try await session.respond(
                to: inferencePrompt(
                    text: normalizedText
                ),
                generating: InferredRecipe.self
            ).content
            let sanitized = sanitizedInference(inferred)
            if isMeaningfulInference(sanitized) {
                return sanitized
            }
        } catch {
            // Fall back to deterministic extraction below.
        }

        guard isMeaningfulInference(fallback) else {
            throw RecipeInferenceError.insufficientContent
        }
        return fallback
    }

    static func inferencePrompt(
        text: String
    ) -> String {
        """
        Extract a recipe form from the following text.
        Return only the structured fields defined by the schema.

        Text:
        \(text)
        """
    }

    static func normalizedInferenceInput(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func sanitizedInference(
        _ inference: InferredRecipe
    ) -> InferredRecipe {
        .init(
            name: sanitizedInferenceLine(inference.name),
            servingSize: max(inference.servingSize, .zero),
            cookingTime: max(inference.cookingTime, .zero),
            ingredients: inference.ingredients.compactMap { inferredIngredient in
                let ingredient = sanitizedInferenceLine(
                    inferredIngredient.ingredient
                )
                guard ingredient.isNotEmpty else {
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
                return normalizedStep.isNotEmpty ? normalizedStep : nil
            },
            categories: inference.categories.compactMap { category in
                let normalizedCategory = sanitizedInferenceLine(category)
                return normalizedCategory.isNotEmpty ? normalizedCategory : nil
            },
            note: sanitizedInferenceLine(inference.note)
        )
    }

    static func isMeaningfulInference(
        _ inference: InferredRecipe
    ) -> Bool {
        if inference.ingredients.isNotEmpty || inference.steps.isNotEmpty {
            return true
        }

        let metadataScore = [
            inference.name.isNotEmpty,
            inference.servingSize > .zero,
            inference.cookingTime > .zero,
            inference.categories.isNotEmpty,
            inference.note.isNotEmpty
        ].filter(\.self).count
        return metadataScore >= InferenceConstants.minimumMeaningfulMetadataScore
    }

    static func sanitizedInferenceLine(
        _ value: String
    ) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedValue.isNotEmpty else {
            return .empty
        }
        return RecipeBlurbService.collapsedWhitespace(trimmedValue)
    }

    static func fallbackInference(from text: String) -> InferredRecipe {
        let lines = text.components(separatedBy: .newlines)
        let ingredients = fallbackSectionItems(
            from: lines,
            headings: ingredientSectionHeadings
        ).map { ingredient in
            InferredRecipeIngredient(
                ingredient: ingredient,
                amount: .empty
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
            guard normalizedLine.isNotEmpty else {
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
        return .empty
    }

    static func fallbackSectionItems(
        from lines: [String],
        headings: [String]
    ) -> [String] {
        var collectedItems = [String]()
        var isCollecting = false

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedLine.isNotEmpty else {
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
                if normalizedItem.isNotEmpty {
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
            if normalizedItem.isNotEmpty {
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
        return .empty
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
