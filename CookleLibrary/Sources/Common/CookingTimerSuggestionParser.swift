import Foundation

/// Parses timer suggestions from recipe step text.
public enum CookingTimerSuggestionParser {
    /// Returns a timer suggestion when the step contains an explicit minute value.
    public static func suggestedTimer(
        for step: String
    ) -> CookingTimerSuggestion? {
        let normalizedStep = (step.applyingTransform(
            .fullwidthToHalfwidth,
            reverse: false
        ) ?? step).lowercased()
        let minutePattern = #"(\d+)\s*(?:min|mins|minute|minutes|分)"#

        guard let matchedRange = normalizedStep.range(
            of: minutePattern,
            options: .regularExpression
        ) else {
            return nil
        }

        let matchedText = String(normalizedStep[matchedRange])
        let digits = matchedText
            .components(
                separatedBy: CharacterSet.decimalDigits.inverted
            )
            .joined()
        guard let minutes = Int(digits),
              minutes > .zero else {
            return nil
        }

        return .init(
            minutes: minutes
        )
    }
}
