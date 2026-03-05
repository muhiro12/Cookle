import Foundation

/// Planner for recipe suggestion notification schedules.
public enum DailyRecipeSuggestionService {
    private enum HashConstants {
        static let secondsPerDay = Int("86400") ?? .zero
        static let multiplier = Int64("1103515245") ?? .zero
        static let increment = Int64("12345") ?? .zero
    }

    /// Builds future daily suggestion entries from the supplied candidates.
    public static func buildSuggestions(
        candidates: [DailyRecipeSuggestionCandidate],
        hour: Int,
        minute: Int,
        now: Date = .now,
        calendar: Calendar = .current,
        daysAhead: Int = 14,
        identifierPrefix: String = "daily-recipe-suggestion-"
    ) -> [DailyRecipeSuggestion] {
        guard !candidates.isEmpty else {
            return []
        }

        let orderedCandidates = sortedCandidates(candidates)

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

            suggestions.append(
                makeSuggestion(
                    for: orderedCandidates[recipeIndex],
                    targetDay: targetDay,
                    notifyDate: notifyDate,
                    calendar: calendar,
                    identifierPrefix: identifierPrefix
                )
            )
        }
        return suggestions
    }

    private static func recipeIndexForDay(
        day: Date,
        calendar: Calendar,
        recipeCount: Int
    ) -> Int {
        let dayNumber = Int(
            calendar.startOfDay(for: day).timeIntervalSince1970
                / Double(HashConstants.secondsPerDay)
        )
        let mixed = Int64(dayNumber) &* HashConstants.multiplier &+ HashConstants.increment
        let positiveMixed = mixed >= 0 ? mixed : -mixed
        return Int(positiveMixed % Int64(recipeCount))
    }

    private static func sortedCandidates(
        _ candidates: [DailyRecipeSuggestionCandidate]
    ) -> [DailyRecipeSuggestionCandidate] {
        candidates.sorted { lhs, rhs in
            if lhs.name != rhs.name {
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            return lhs.stableIdentifier < rhs.stableIdentifier
        }
    }

    private static func makeSuggestion(
        for candidate: DailyRecipeSuggestionCandidate,
        targetDay: Date,
        notifyDate: Date,
        calendar: Calendar,
        identifierPrefix: String
    ) -> DailyRecipeSuggestion {
        let dayIdentifier = calendar.dateComponents(
            [.year, .month, .day],
            from: targetDay
        )
        let year = dayIdentifier.year ?? .zero
        let month = dayIdentifier.month ?? .zero
        let day = dayIdentifier.day ?? .zero
        let identifier = "\(identifierPrefix)\(year)-\(month)-\(day)"
        return .init(
            identifier: identifier,
            recipeName: candidate.name,
            stableIdentifier: candidate.stableIdentifier,
            notifyDate: notifyDate
        )
    }
}
