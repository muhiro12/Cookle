import Foundation

/// Converts web page data into source text for the existing reviewed inference flow.
public enum RecipeWebsiteImportOperations {
    /// Upper bound for text handed to the editable inference input.
    public static let maximumTextLength = 16_000

    /// Accepts ordinary HTTP(S) page addresses without embedded credentials.
    public static func websiteURL(from text: String) -> URL? {
        guard let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
              ["https", "http"].contains(url.scheme?.lowercased()),
              let host = url.host, host.contains("."),
              url.user == nil, url.password == nil else {
            return nil
        }
        return url
    }

    /// Rejects oversized and ambiguous inputs instead of silently dropping recipe content.
    public static func sourceText(structuredData: [String], visibleText: String) throws -> String {
        try source(structuredData: structuredData, visibleText: visibleText).text
    }

    /// Retains source facts separately from the editable text so inference cannot silently rewrite them.
    public static func source(
        structuredData: [String],
        visibleText: String,
        knownIngredients: [RecipeInferenceIngredient] = [],
        equipment: [String] = [],
        knownSteps: [String] = [],
        sourceNotes: [String] = [],
        servingText: String = ""
    ) throws -> RecipeWebsiteSource {
        guard structuredData.reduce(0, { $0 + $1.utf8.count }) <= maximumStructuredBytes else {
            throw RecipeWebsiteImportError.contentTooLarge
        }
        var recipes: [[String: Any]] = []
        for source in structuredData {
            guard let data = source.data(using: .utf8),
                  let value = try? JSONSerialization.jsonObject(with: data) else {
                continue
            }
            collectRecipes(in: value, depth: 0, into: &recipes)
        }
        let texts = Array(Set(recipes.map(recipeText))).sorted()
        guard texts.count <= 1 else {
            throw RecipeWebsiteImportError.multipleRecipes
        }
        let recipe = recipes.first ?? [:]
        let structuredSteps = instructionSteps(recipe["recipeInstructions"])
        let steps = structuredSteps.isEmpty ? knownSteps : structuredSteps
        let supplements = sourceNotes + equipment + [servingText] + (structuredSteps.isEmpty ? knownSteps : [])
        let text = (texts.first.map { metadata in
            ([metadata] + supplements).filter { !$0.isEmpty }.joined(separator: "\n\n")
        } ?? visibleText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw RecipeWebsiteImportError.noContent
        }
        guard text.count <= maximumTextLength,
              supplements.joined(separator: "\n").count <= maximumTextLength else {
            throw RecipeWebsiteImportError.contentTooLarge
        }
        let details = [plainText(recipe["description"], depth: 0), plainText(recipe["tool"], depth: 0)]
            + equipment + sourceNotes
        return .init(
            text: text,
            name: plainText(recipe["name"], depth: 0),
            ingredients: (recipe["recipeIngredient"] as? [Any] ?? []).map { plainText($0, depth: 0) },
            knownIngredients: recipes.isEmpty ? knownIngredients : [],
            steps: steps,
            yield: resolvedYield(plainText(recipe["recipeYield"], depth: 0), servingText: servingText),
            cookingDuration: plainText(recipe["cookTime"], depth: 0),
            attribution: plainText(recipe["author"], depth: 0),
            details: details.filter { !$0.isEmpty }.joined(separator: "\n\n"),
            hasStructuredRecipe: !recipes.isEmpty
        )
    }

    /// Appends the original source address outside model-generated text.
    public static func note(_ note: String, sourceURL: URL?) -> String {
        guard let sourceURL else {
            return note
        }
        return [note.trimmingCharacters(in: .whitespacesAndNewlines), sourceURL.absoluteString]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }
}

private extension RecipeWebsiteImportOperations {
    static let maximumDepth = 20
    static let maximumStructuredBytes = 1_000_000

    static func collectRecipes(in value: Any, depth: Int, into recipes: inout [[String: Any]]) {
        guard depth < maximumDepth else {
            return
        }
        if let values = value as? [Any] {
            for element in values {
                collectRecipes(in: element, depth: depth + 1, into: &recipes)
            }
        } else if let object = value as? [String: Any] {
            let types = object["@type"] as? [String] ?? [object["@type"] as? String ?? ""]
            if types.contains("Recipe") {
                recipes.append(object)
            } else if let graph = object["@graph"] {
                collectRecipes(in: graph, depth: depth + 1, into: &recipes)
            }
        }
    }

    static func resolvedYield(_ metadata: String, servingText: String) -> String {
        guard !metadata.isEmpty else {
            return servingText
        }
        // Numeric metadata alone does not establish that a yield describes servings.
        guard let value = Double(metadata), !servingText.isEmpty else {
            return metadata
        }
        let pattern = #/(?i)(?:serves\s+)?([0-9]+)(?:\s*(?:人分|人前|servings?|people|persons?))?/#
        let count = servingText.wholeMatch(of: pattern)
        guard let count, Double(count.1) == value else {
            return metadata
        }
        return servingText
    }

    static func instructionSteps(_ value: Any?) -> [String] {
        if let array = value as? [Any] {
            return array.map { plainText($0, depth: 0) }.filter { !$0.isEmpty }
        }
        let text = plainText(value, depth: 0)
        return text.isEmpty ? [] : [text]
    }

    static func recipeText(_ recipe: [String: Any]) -> String {
        let fields = [
            ("name", "Name"),
            ("author", "Author"),
            ("description", "Description"),
            ("recipeYield", "Yield (not necessarily servings)"),
            ("prepTime", "Preparation time"),
            ("cookTime", "Cooking time"),
            ("totalTime", "Total time"),
            ("recipeIngredient", "Ingredients"),
            ("recipeInstructions", "Steps"),
            ("tool", "Equipment")
        ]
        return fields.compactMap { key, label in
            let text = plainText(recipe[key], depth: 0)
            return text.isEmpty ? nil : "\(label):\n\(text)"
        }
        .joined(separator: "\n\n")
    }

    static func plainText(_ value: Any?, depth: Int) -> String {
        guard depth < maximumDepth else {
            return ""
        }
        if let text = value as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let number = value as? Double {
            return number.description
        }
        if let array = value as? [Any] {
            return array.map { plainText($0, depth: depth + 1) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
        }
        guard let object = value as? [String: Any] else {
            return ""
        }
        let name = plainText(object["name"], depth: depth + 1)
        let text = plainText(object["text"], depth: depth + 1)
        let children = plainText(object["itemListElement"], depth: depth + 1)
        return [name, text == name ? "" : text, children]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
