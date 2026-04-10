import Foundation

enum DiaryListSummary {
    private enum Constants {
        static let maxLength = 80
        static let fallbackText = "No recipes or note yet"
    }

    static func text(
        recipeNames: [String],
        note: String
    ) -> String {
        if recipeNames.isNotEmpty {
            return recipeNames.joined(separator: ", ")
        }

        let normalizedNote = normalized(note)
        if normalizedNote.isNotEmpty {
            return truncated(
                normalizedNote,
                maxLength: Constants.maxLength
            )
        }

        return Constants.fallbackText
    }
}

private extension DiaryListSummary {
    static func normalized(
        _ value: String
    ) -> String {
        value
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    static func truncated(
        _ value: String,
        maxLength: Int
    ) -> String {
        guard value.count > maxLength else {
            return value
        }

        let prefix = String(value.prefix(maxLength))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return prefix + "..."
    }
}
