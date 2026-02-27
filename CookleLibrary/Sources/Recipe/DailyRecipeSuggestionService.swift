import Foundation

/// Candidate used to generate daily suggestion schedules.
public struct DailyRecipeSuggestionCandidate: Sendable {
    public let name: String
    public let stableIdentifier: String

    public init(
        name: String,
        stableIdentifier: String
    ) {
        self.name = name
        self.stableIdentifier = stableIdentifier
    }
}

/// Computed daily suggestion schedule entry.
public struct DailyRecipeSuggestion: Sendable {
    public let identifier: String
    public let recipeName: String
    public let notifyDate: Date

    public init(
        identifier: String,
        recipeName: String,
        notifyDate: Date
    ) {
        self.identifier = identifier
        self.recipeName = recipeName
        self.notifyDate = notifyDate
    }
}

/// Planner for recipe suggestion notification schedules.
public enum DailyRecipeSuggestionService {
    public static func buildSuggestions(
        candidates: [DailyRecipeSuggestionCandidate],
        now: Date = .now,
        calendar: Calendar = .current,
        hour: Int,
        minute: Int,
        daysAhead: Int = 14,
        identifierPrefix: String = "daily-recipe-suggestion-"
    ) -> [DailyRecipeSuggestion] {
        guard !candidates.isEmpty else {
            return []
        }

        let orderedCandidates = candidates.sorted { lhs, rhs in
            if lhs.name != rhs.name {
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            return lhs.stableIdentifier < rhs.stableIdentifier
        }

        var suggestions = [DailyRecipeSuggestion]()
        let startOfToday = calendar.startOfDay(for: now)
        var previousIndex: Int?

        for dayOffset in 0..<daysAhead {
            guard let targetDay = calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: startOfToday
            ),
            let notifyDate = calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: targetDay
            ),
            notifyDate > now else {
                continue
            }

            var recipeIndex = recipeIndexForDay(
                day: targetDay,
                calendar: calendar,
                recipeCount: orderedCandidates.count
            )
            if orderedCandidates.count > 1,
               let previousIndex,
               previousIndex == recipeIndex {
                recipeIndex = (recipeIndex + 1) % orderedCandidates.count
            }
            previousIndex = recipeIndex

            let candidate = orderedCandidates[recipeIndex]
            let dayIdentifier = calendar.dateComponents(
                [.year, .month, .day],
                from: targetDay
            )
            let identifier = "\(identifierPrefix)\(dayIdentifier.year ?? 0)-\(dayIdentifier.month ?? 0)-\(dayIdentifier.day ?? 0)"
            suggestions.append(
                .init(
                    identifier: identifier,
                    recipeName: candidate.name,
                    notifyDate: notifyDate
                )
            )
        }
        return suggestions
    }
}

private extension DailyRecipeSuggestionService {
    static func recipeIndexForDay(
        day: Date,
        calendar: Calendar,
        recipeCount: Int
    ) -> Int {
        let dayNumber = Int(
            calendar.startOfDay(for: day).timeIntervalSince1970 / 86_400
        )
        let mixed = Int64(dayNumber) &* 1_103_515_245 &+ 12_345
        let positiveMixed = mixed >= 0 ? mixed : -mixed
        return Int(positiveMixed % Int64(recipeCount))
    }
}
