import Foundation

extension RecipeService {
    /// Only explicit recipe-level cooking metadata can populate the numeric field.
    static func cookingTimeStatement(in text: String) -> String? {
        let pattern = #"""
            (?ix)
            ^(?: cook(?:ing)? \s* time | 調理時間 | temps \s+ de \s+ cuisson
            | tiempo \s+ de \s+ cocción | 烹饪时间 )
            (?= \s | [:：0-9０-９(（] | $ )
            """#
        return text.components(separatedBy: .newlines)
            .map { line in
                strippedInferenceMarkup(line).replacingOccurrences(of: "**", with: "")
            }
            .first { line in
                line.range(of: pattern, options: .regularExpression) != nil
            }
    }

    static func fallbackCookingTime(from text: String) -> Int {
        guard let statement = cookingTimeStatement(in: text) else {
            return .zero
        }
        let value = halfwidthDigits(in: statement)
        guard value.range(of: ambiguousCookingTimePattern, options: .regularExpression) == nil else {
            return .zero
        }
        let minutesInHeading = #"(?i)[（(](?:minutes|minutos|分|分钟)[）)]\s*[:：]?\s*\d+\s*$"#
        if value.range(of: minutesInHeading, options: .regularExpression) != nil {
            return extractedNumber(in: value, pattern: minutesInHeading)
        }
        return extractedNumber(in: value, pattern: fallbackCookingTimePattern)
    }
}
