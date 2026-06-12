import Foundation

/// Internal deterministic blurb collaborator used by recipe Operations.
enum RecipeBlurbService {
    private enum BlurbConstants {
        static let minimumDetailedStepLength = 12
        static let ingredientSummaryCount = 2
        static let ellipsisLength = 3
    }

    /// Returns a concise, deterministic blurb from recipe steps, note, or ingredients.
    static func makeBlurb(
        request: RecipeBlurbRequest,
        maxLength: Int = 72
    ) -> String? {
        let normalizedSteps = normalizedLines(from: request.steps)

        if let step = normalizedSteps.first(where: { line in
            line.count >= BlurbConstants.minimumDetailedStepLength
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
            .prefix(BlurbConstants.ingredientSummaryCount)
            .joined(separator: ", ")
        if ingredientSummary.isEmpty {
            return nil
        }

        return truncatedBlurb(ingredientSummary, maxLength: maxLength)
    }

    static func normalizedLines(from values: [String]) -> [String] {
        values.compactMap { value in
            let normalizedValue = normalizedLine(from: value)
            return normalizedValue.isEmpty ? nil : normalizedValue
        }
    }

    static func normalizedNoteLine(from value: String) -> String? {
        for line in value.components(separatedBy: .newlines) {
            let normalizedValue = normalizedLine(from: line)
            if !normalizedValue.isEmpty {
                return normalizedValue
            }
        }
        return nil
    }

    static func normalizedIngredients(from values: [String]) -> [String] {
        values.compactMap { value in
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedValue.isEmpty else {
                return nil
            }
            let collapsedValue = collapsedWhitespace(trimmedValue)
            return !collapsedValue.isEmpty ? collapsedValue : nil
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
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    static func truncatedBlurb(_ value: String, maxLength: Int) -> String? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty, maxLength > 0 else {
            return nil
        }
        guard trimmedValue.count > maxLength else {
            return trimmedValue
        }
        guard maxLength > BlurbConstants.ellipsisLength else {
            return String(trimmedValue.prefix(maxLength))
        }

        let prefixLength = maxLength - BlurbConstants.ellipsisLength
        let rawPrefix = String(trimmedValue.prefix(prefixLength))
        let prefixWithoutTrailingWhitespace = rawPrefix.trimmingCharacters(in: .whitespacesAndNewlines)
        let truncatedPrefix: String
        if let lastSpaceIndex = prefixWithoutTrailingWhitespace.lastIndex(of: " ") {
            let candidate = String(prefixWithoutTrailingWhitespace[..<lastSpaceIndex])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !candidate.isEmpty {
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
        let safePrefix = !cleanedPrefix.isEmpty ? cleanedPrefix : prefixWithoutTrailingWhitespace
        return safePrefix + "..."
    }

    private static func normalizedLine(from value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            return ""
        }

        let collapsedValue = collapsedWhitespace(trimmedValue)
        let strippedValue = strippingListPrefix(from: collapsedValue)
        return collapsedWhitespace(strippedValue)
    }
}
