import Foundation
import MHNotificationPlans

/// Planner for recipe suggestion notification schedules.
public enum DailyRecipeSuggestionService {
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
        guard let deliveryTime = MHNotificationTime(
            hour: hour,
            minute: minute
        ) else {
            return []
        }

        return MHSuggestionPlanner.build(
            candidates: suggestionCandidates(from: candidates),
            policy: .init(
                deliveryTime: deliveryTime,
                daysAhead: daysAhead,
                identifierPrefix: identifierPrefix
            ),
            now: now,
            calendar: calendar
        )
        .map { plan in
            .init(
                identifier: localIdentifier(
                    for: plan.notifyDate,
                    calendar: calendar,
                    identifierPrefix: identifierPrefix
                ),
                recipeName: plan.title,
                stableIdentifier: plan.stableIdentifier,
                notifyDate: plan.notifyDate
            )
        }
    }
}

private extension DailyRecipeSuggestionService {
    static func suggestionCandidates(
        from candidates: [DailyRecipeSuggestionCandidate]
    ) -> [MHSuggestionCandidate] {
        candidates.map { candidate in
            .init(
                title: candidate.name,
                stableIdentifier: candidate.stableIdentifier,
                routeURL: CookleDeepLinkURLBuilder.preferredRecipeDetailURL(
                    for: candidate.stableIdentifier
                )
            )
        }
    }

    static func localIdentifier(
        for notifyDate: Date,
        calendar: Calendar,
        identifierPrefix: String
    ) -> String {
        let dayIdentifier = calendar.dateComponents(
            [.year, .month, .day],
            from: notifyDate
        )
        let year = dayIdentifier.year ?? .zero
        let month = dayIdentifier.month ?? .zero
        let day = dayIdentifier.day ?? .zero
        return "\(identifierPrefix)\(year)-\(month)-\(day)"
    }
}
