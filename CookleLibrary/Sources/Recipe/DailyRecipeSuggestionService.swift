import Foundation
import MHPlatformCore

/// Internal planner for recipe suggestion notification Operations.
enum DailyRecipeSuggestionService {
    private enum QualityConstants {
        static let minimumFocusedCandidateCount = 2
        static let recentCookingCooldownDays = 2
    }

    /// Builds future daily suggestion entries from the supplied candidates.
    static func buildSuggestions(
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
            candidates: suggestionCandidates(
                from: candidates,
                now: now,
                calendar: calendar
            ),
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
        from candidates: [DailyRecipeSuggestionCandidate],
        now: Date,
        calendar: Calendar
    ) -> [MHSuggestionCandidate] {
        qualityCandidates(
            from: candidates,
            now: now,
            calendar: calendar
        )
        .map { candidate in
            .init(
                title: candidate.name,
                stableIdentifier: candidate.stableIdentifier,
                routeURL: CookleDeepLinkURLBuilder.preferredRecipeDetailURL(
                    for: candidate.stableIdentifier
                )
            )
        }
    }

    static func qualityCandidates(
        from candidates: [DailyRecipeSuggestionCandidate],
        now: Date,
        calendar: Calendar
    ) -> [DailyRecipeSuggestionCandidate] {
        let validCandidates = deduplicatedCandidates(
            from: candidates.compactMap(normalizedCandidate)
        )
        guard validCandidates.isEmpty == false else {
            return []
        }

        let focusedCandidates = focusCandidates(
            validCandidates
        )
        return excludeRecentlyCookedCandidatesIfPossible(
            focusedCandidates,
            now: now,
            calendar: calendar
        )
    }

    static func normalizedCandidate(
        _ candidate: DailyRecipeSuggestionCandidate
    ) -> DailyRecipeSuggestionCandidate? {
        let name = collapsedWhitespace(
            in: candidate.name
        )
        let stableIdentifier = candidate.stableIdentifier.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard name.isEmpty == false,
              stableIdentifier.isEmpty == false else {
            return nil
        }

        return .init(
            name: name,
            stableIdentifier: stableIdentifier,
            hasPhoto: candidate.hasPhoto,
            ingredientCount: candidate.ingredientCount,
            cookingTime: candidate.cookingTime,
            madeCount: candidate.madeCount,
            lastCookedDate: candidate.lastCookedDate
        )
    }

    static func deduplicatedCandidates(
        from candidates: [DailyRecipeSuggestionCandidate]
    ) -> [DailyRecipeSuggestionCandidate] {
        var seenIdentifiers = Set<String>()
        var result = [DailyRecipeSuggestionCandidate]()

        for candidate in candidates
        where seenIdentifiers.insert(candidate.stableIdentifier).inserted {
            result.append(candidate)
        }

        return result
    }

    static func focusCandidates(
        _ candidates: [DailyRecipeSuggestionCandidate]
    ) -> [DailyRecipeSuggestionCandidate] {
        let informativeCandidates = candidates.filter { candidate in
            candidate.hasPhoto
                || candidate.ingredientCount > .zero
                || candidate.cookingTime > .zero
                || candidate.madeCount > .zero
        }
        if informativeCandidates.count >= QualityConstants.minimumFocusedCandidateCount {
            return informativeCandidates
        }

        return candidates
    }

    static func excludeRecentlyCookedCandidatesIfPossible(
        _ candidates: [DailyRecipeSuggestionCandidate],
        now: Date,
        calendar: Calendar
    ) -> [DailyRecipeSuggestionCandidate] {
        guard let cutoffDate = calendar.date(
            byAdding: .day,
            value: -QualityConstants.recentCookingCooldownDays,
            to: calendar.startOfDay(for: now)
        ) else {
            return candidates
        }

        let nonRecentCandidates = candidates.filter { candidate in
            guard let lastCookedDate = candidate.lastCookedDate else {
                return true
            }
            return lastCookedDate < cutoffDate
        }

        guard nonRecentCandidates.count >= QualityConstants.minimumFocusedCandidateCount else {
            return candidates
        }

        return nonRecentCandidates
    }

    static func collapsedWhitespace(
        in value: String
    ) -> String {
        value
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
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
