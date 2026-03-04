import Foundation

/// Input used to derive a short deterministic recipe blurb.
public struct RecipeBlurbRequest: Sendable {
    public let steps: [String]
    public let ingredients: [String]
    public let note: String

    public init(
        steps: [String],
        ingredients: [String],
        note: String
    ) {
        self.steps = steps
        self.ingredients = ingredients
        self.note = note
    }
}

/// Builds short deterministic recipe blurbs from saved recipe content.
public enum RecipeBlurbService {
    public static func makeBlurb(
        request: RecipeBlurbRequest,
        maxLength: Int = 72
    ) -> String? {
        let normalizedSteps = normalizedLines(from: request.steps)

        if let step = normalizedSteps.first(where: { line in
            line.count >= 12
        }) {
            return truncatedBlurb(step, maxLength: maxLength)
        }

        if let firstStep = normalizedSteps.first {
            return truncatedBlurb(firstStep, maxLength: maxLength)
        }

        if let noteLine = normalizedNoteLine(from: request.note) {
            return truncatedBlurb(noteLine, maxLength: maxLength)
        }

        let ingredientSummary = normalizedIngredients(from: request.ingredients)
            .prefix(2)
            .joined(separator: ", ")
        if ingredientSummary.isEmpty {
            return nil
        }

        return truncatedBlurb(ingredientSummary, maxLength: maxLength)
    }
}

extension RecipeBlurbService {
    static func normalizedLines(from values: [String]) -> [String] {
        values.compactMap { value in
            let normalizedValue = normalizedLine(from: value)
            return normalizedValue.isEmpty ? nil : normalizedValue
        }
    }

    static func normalizedNoteLine(from value: String) -> String? {
        for line in value.components(separatedBy: .newlines) {
            let normalizedValue = normalizedLine(from: line)
            if normalizedValue.isNotEmpty {
                return normalizedValue
            }
        }
        return nil
    }

    static func normalizedIngredients(from values: [String]) -> [String] {
        values.compactMap { value in
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedValue.isNotEmpty else {
                return nil
            }
            let collapsedValue = collapsedWhitespace(trimmedValue)
            return collapsedValue.isNotEmpty ? collapsedValue : nil
        }
    }

    static func strippingListPrefix(from value: String) -> String {
        let patterns = [
            #"^\d+\.\s*"#,
            #"^\d+\)\s*"#,
            #"^[-*•・]\s*"#
        ]

        for pattern in patterns {
            if let range = value.range(of: pattern, options: .regularExpression) {
                var strippedValue = value
                strippedValue.replaceSubrange(range, with: "")
                return strippedValue.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func collapsedWhitespace(_ value: String) -> String {
        value
            .components(separatedBy: .whitespacesAndNewlines)
            .filter(\.isNotEmpty)
            .joined(separator: " ")
    }

    static func truncatedBlurb(_ value: String, maxLength: Int) -> String? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedValue.isNotEmpty, maxLength > 0 else {
            return nil
        }
        guard trimmedValue.count > maxLength else {
            return trimmedValue
        }
        guard maxLength > 3 else {
            return String(trimmedValue.prefix(maxLength))
        }

        let prefixLength = maxLength - 3
        let rawPrefix = String(trimmedValue.prefix(prefixLength))
        let prefixWithoutTrailingWhitespace = rawPrefix.trimmingCharacters(in: .whitespacesAndNewlines)
        let truncatedPrefix: String
        if let lastSpaceIndex = prefixWithoutTrailingWhitespace.lastIndex(of: " ") {
            let candidate = String(prefixWithoutTrailingWhitespace[..<lastSpaceIndex])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if candidate.isNotEmpty {
                truncatedPrefix = candidate
            } else {
                truncatedPrefix = prefixWithoutTrailingWhitespace
            }
        } else {
            truncatedPrefix = prefixWithoutTrailingWhitespace
        }

        let cleanedPrefix = truncatedPrefix.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        )
        let safePrefix = cleanedPrefix.isNotEmpty ? cleanedPrefix : prefixWithoutTrailingWhitespace
        return safePrefix + "..."
    }
}

private extension RecipeBlurbService {
    static func normalizedLine(from value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedValue.isNotEmpty else {
            return ""
        }

        let collapsedValue = collapsedWhitespace(trimmedValue)
        let strippedValue = strippingListPrefix(from: collapsedValue)
        return collapsedWhitespace(strippedValue)
    }
}
