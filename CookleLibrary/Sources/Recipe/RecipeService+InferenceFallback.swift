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
        "材料", "ingrédients", "ingredientes", "食材"
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
        "方法", "étapes", "préparation", "pasos", "preparación", "步骤", "做法"
    ]

    static let noteSectionHeadings = ["note", "notes", "メモ", "備考", "notas", "备注"]
    static let sourceSectionHeadings = ["source", "出典", "fuente", "来源"]
    static let categorySectionHeadings = ["category", "categories", "カテゴリ", "catégories", "categorías", "分类"]
    static let allSectionHeadings = ingredientSectionHeadings + stepSectionHeadings
        + noteSectionHeadings + sourceSectionHeadings + categorySectionHeadings

    /// Serving counts the fallback reads: `Serves 4`, `4 servings`, `4人分`,
    /// `4人前`, and `for 4`, except where `for` starts a duration or a
    /// temperature such as `for 8 minutes` or `for 10-15 minutes`.
    static let fallbackServingSizePattern = #"""
        (?ix)
        (?: serves | servings | serving \s+ size | 人数 ) \s* [:：]? \s* \d+
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
        (?: [-–—~〜～] | to | or | / | [.,]
        | (?: hours? | hrs? | heures? | horas? | h | 時間 | 小时 | 小時 )
        \s* (?: and | et | y | と | 和 | [,、] )? ) \s*
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
        } else {
            // A step duration is not the recipe's cooking time, even if the model promotes it.
            result.cookingTime = fallbackCookingTime(from: sourceText)
            if result.cookingTime == .zero, let statement = cookingTimeStatement(in: sourceText) {
                result.note = noteRetaining(statement, in: result.note)
            }
        }
        for source in fallbackSectionItems(
            from: sourceText.components(separatedBy: .newlines),
            headings: sourceSectionHeadings
        ) {
            result.note = noteRetaining(source, in: result.note)
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
                (?: serves | servings | serving \s+ size | 人数 ) \s* [:：]? \s*
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
        let ingredients = fallbackIngredients(from: fallbackSectionItems(
            from: lines,
            headings: ingredientSectionHeadings
        ))
        let steps = fallbackSectionItems(
            from: lines,
            headings: stepSectionHeadings,
            joinsIndentedContinuations: true
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
            cookingTime: fallbackCookingTime(from: text),
            ingredients: ingredients,
            steps: steps,
            categories: fallbackSectionItems(from: lines, headings: categorySectionHeadings),
            note: fallbackSectionItems(from: lines, headings: noteSectionHeadings)
                .joined(separator: "\n")
        )
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
