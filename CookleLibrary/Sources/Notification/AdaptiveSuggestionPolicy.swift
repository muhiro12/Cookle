import Foundation

enum AdaptiveSuggestionPolicy {
    static let historyDays = 14
    private static let minimumDays = 2
    private static let halfDivisor = 2
    private static let minutesPerHour = 60
    private static let halfHourMinutes = 30
    private static let notificationLeadMinutes = 30
    private static let minutesPerDay = 1_440

    static func isValidMinute(_ minute: Int) -> Bool {
        (.zero..<minutesPerDay).contains(minute)
    }

    static func notificationMinute(for learnedMinute: Int) -> Int {
        (learnedMinute - notificationLeadMinutes + minutesPerDay) % minutesPerDay
    }

    static func recordingUsage(
        in previous: AdaptiveRecipeSuggestionState,
        at date: Date,
        isNotificationResponse: Bool,
        calendar: Calendar
    ) -> AdaptiveRecipeSuggestionState {
        var state = reconciled(previous, now: date, calendar: calendar)
        let meal = DiaryTopSuggestionService.mealType(for: date, calendar: calendar)
        state.lastUsedAt[meal] = date
        if !isNotificationResponse {
            let key = dayKey(date, calendar: calendar)
            if state.firstOpenMinutesByDay[key]?[meal] == nil {
                let components = calendar.dateComponents([.hour, .minute], from: date)
                state.firstOpenMinutesByDay[key, default: [:]][meal] =
                    (components.hour ?? .zero) * minutesPerHour + (components.minute ?? .zero)
            }
        }
        return reconciled(state, now: date, calendar: calendar)
    }

    static func reconciled(
        _ previous: AdaptiveRecipeSuggestionState,
        now: Date,
        calendar: Calendar
    ) -> AdaptiveRecipeSuggestionState {
        var state = previous
        let allowedDays = Set((.zero..<historyDays).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: now).map { date in
                dayKey(date, calendar: calendar)
            }
        })
        state.firstOpenMinutesByDay = state.firstOpenMinutesByDay.filter { key, value in
            allowedDays.contains(key) && !value.isEmpty
        }
        state.lastUsedAt = state.lastUsedAt.filter { _, usedAt in
            guard usedAt <= now,
                  let expiry = calendar.date(byAdding: .day, value: historyDays, to: usedAt) else {
                return false
            }
            return now < expiry
        }
        state.learnedMinutes = state.learnedMinutes.filter { meal, minute in
            state.lastUsedAt[meal] != nil && isValidMinute(minute)
        }
        let independentDays = state.firstOpenMinutesByDay.count
        for meal in DiaryObjectType.allCases {
            let minutes = state.firstOpenMinutesByDay.values.compactMap { day in
                day[meal]
            }
            .sorted()
            guard minutes.count >= minimumDays,
                  minutes.count * halfDivisor >= independentDays,
                  state.lastUsedAt[meal] != nil else {
                continue
            }
            let middle = minutes.count / halfDivisor
            let median = minutes.count.isMultiple(of: halfDivisor)
                ? (minutes[middle - 1] + minutes[middle]) / halfDivisor
                : minutes[middle]
            state.learnedMinutes[meal] = median / halfHourMinutes * halfHourMinutes
        }
        return state
    }

    static func dayKey(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? .zero)-\(components.month ?? .zero)-\(components.day ?? .zero)"
    }
}
