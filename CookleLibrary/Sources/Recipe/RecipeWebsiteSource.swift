import Foundation

/// Source facts retained in memory while a website recipe is being reviewed.
public struct RecipeWebsiteSource: Sendable {
    /// Editable text passed to inference.
    public let text: String
    let name: String
    let ingredients: [String]
    let knownIngredients: [RecipeInferenceIngredient]
    let steps: [String]
    let yield: String
    let cookingDuration: String
    let attribution: String
    let details: String
    let hasStructuredRecipe: Bool

    /// Keeps exact source facts when inferred field splitting would change them.
    public func grounding(_ inference: RecipeInferenceResult) -> RecipeInferenceResult {
        var result = inference
        if !name.isEmpty {
            result.name = name
        }
        if !knownIngredients.isEmpty {
            result.ingredients = knownIngredients
        } else if !ingredients.isEmpty {
            result.ingredients = ingredients.map { groundedIngredient($0, inference: inference) }
        }
        if !steps.isEmpty {
            result.steps = steps
        }
        guard hasStructuredRecipe else {
            result.servingSize = servingCount
            // Accept extra notes only as source excerpts, and do not repeat retained source facts.
            let note = inference.note.trimmingCharacters(in: .whitespacesAndNewlines)
            let isSourceExcerpt = !note.isEmpty && normalized(text).contains(normalized(note))
            let isRetainedFact = normalized(details).contains(normalized(note))
            result.note = [isSourceExcerpt && !isRetainedFact ? note : "", details]
                .filter { !$0.isEmpty }.joined(separator: "\n\n")
            return result
        }
        result.servingSize = servingCount
        result.cookingTime = cookingMinutes
        let facts = [details, yield, attribution].filter { !$0.isEmpty }
        result.note = facts.joined(separator: "\n\n")
        return result
    }
}

private extension RecipeWebsiteSource {
    var servingCount: Int {
        let text = yield.trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = text.wholeMatch(of: #/(?i)serves\s+([0-9]+)/#) {
            return Int(match.1) ?? 0
        }
        guard let match = text.wholeMatch(of: #/(?i)([0-9]+)\s*(人分|人前|servings?|people|persons?)/#) else {
            return 0
        }
        return Int(match.1) ?? 0
    }

    var cookingMinutes: Int {
        guard let match = cookingDuration.wholeMatch(of: #/PT(?:([0-9]+)H)?(?:([0-9]+)M)?/#) else {
            return 0
        }
        let hours = match.1.flatMap { Int($0) } ?? 0
        let minutes = match.2.flatMap { Int($0) } ?? 0
        let minutesPerHour = 60
        guard hours <= (Int.max - minutes) / minutesPerHour else {
            return 0
        }
        return hours * minutesPerHour + minutes
    }

    func groundedIngredient(_ source: String, inference: RecipeInferenceResult) -> RecipeInferenceIngredient {
        if let match = inference.ingredients.first(where: { ingredient in
            normalized(ingredient.ingredient + ingredient.amount) == normalized(source)
                || normalized(ingredient.amount + ingredient.ingredient) == normalized(source)
        }) {
            return match
        }
        if let split = restoredPreparationSplit(source, ingredients: inference.ingredients) {
            return split
        }
        let candidates = inference.ingredients.sorted { $0.amount.count > $1.amount.count }
        for ingredient in candidates where !ingredient.amount.isEmpty {
            if source.hasPrefix(ingredient.amount) {
                let remainder = source.dropFirst(ingredient.amount.count)
                if remainder.first?.isWhitespace == true {
                    return .init(
                        ingredient: remainder.trimmingCharacters(in: .whitespacesAndNewlines),
                        amount: ingredient.amount
                    )
                }
            }
            if source.hasSuffix(ingredient.amount) {
                let ingredientName = source.dropLast(ingredient.amount.count)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !ingredientName.isEmpty {
                    return .init(ingredient: ingredientName, amount: ingredient.amount)
                }
            }
        }
        return .init(ingredient: source, amount: "")
    }

    func restoredPreparationSplit(
        _ source: String,
        ingredients: [RecipeInferenceIngredient]
    ) -> RecipeInferenceIngredient? {
        for ingredient in ingredients where !ingredient.ingredient.isEmpty {
            guard let range = source.range(of: ingredient.ingredient),
                  source.first?.isNumber == true, range.lowerBound > source.startIndex else {
                continue
            }
            let prefix = source[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            let suffix = String(source[range.upperBound...])
            guard normalized(prefix + suffix) == normalized(ingredient.amount) else {
                continue
            }
            return .init(ingredient: String(source[range.lowerBound...]), amount: prefix)
        }
        return nil
    }

    func normalized(_ text: String) -> String {
        text.filter { !$0.isWhitespace }
    }
}
