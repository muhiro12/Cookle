import Foundation

/// One device-local preference value for bounded usage learning and accepted times.
public struct AdaptiveRecipeSuggestionState: Codable, Equatable, Sendable {
    /// First independent opens, in local minutes, keyed by local calendar day and meal.
    public internal(set) var firstOpenMinutesByDay: [String: [DiaryObjectType: Int]]
    /// Learned local usage times rounded down to half hours, retained while the meal is used.
    public internal(set) var learnedMinutes: [DiaryObjectType: Int]
    /// Actual use, including notification opens, independently renews each meal's expiry.
    public internal(set) var lastUsedAt: [DiaryObjectType: Date]

    /// Starts without history or a fixed-time fallback.
    public init() {
        firstOpenMinutesByDay = [:]
        learnedMinutes = [:]
        lastUsedAt = [:]
    }

    /// Reads the single preference value; malformed or unbounded data is not adopted.
    public static func decoded(from value: String?) -> Self? {
        guard let data = value?.data(using: .utf8),
              let state = try? JSONDecoder().decode(Self.self, from: data),
              state.firstOpenMinutesByDay.count <= AdaptiveSuggestionPolicy.historyDays,
              state.firstOpenMinutesByDay.values.allSatisfy({ day in
                day.values.allSatisfy(AdaptiveSuggestionPolicy.isValidMinute)
              }),
              state.learnedMinutes.values.allSatisfy(AdaptiveSuggestionPolicy.isValidMinute) else {
            return nil
        }
        return state
    }

    /// Encodes only this small record, without a database or a shared-account store.
    public func encodedString() -> String? {
        guard let data = try? JSONEncoder().encode(self) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
