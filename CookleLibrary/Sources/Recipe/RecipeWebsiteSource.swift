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
            result.ingredients = ingredients.map { source in
                if let match = inference.ingredients.first(where: { ingredient in
                    normalized(ingredient.ingredient + ingredient.amount) == normalized(source)
                        || normalized(ingredient.amount + ingredient.ingredient) == normalized(source)
                }) {
                    return match
                }
                for ingredient in inference.ingredients where !ingredient.amount.isEmpty {
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
        }
        if !steps.isEmpty {
            result.steps = steps
        }
        guard hasStructuredRecipe else {
            result.note = [inference.note, details].filter { !$0.isEmpty }.joined(separator: "\n\n")
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
        guard let match = text.wholeMatch(of: #/([0-9]+)\s*(人分|人前|servings?|people|persons?)/#) else {
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

    func normalized(_ text: String) -> String {
        text.filter { !$0.isWhitespace }
    }
}
