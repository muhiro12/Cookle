import Foundation

/// Errors raised when more than one diary would represent the same calendar day.
public enum DiaryDayConflictError: Equatable, LocalizedError, Sendable {
    /// Another diary already occupies the requested calendar day.
    case dayAlreadyOccupied
    /// Persisted data contains multiple diaries for one calendar day.
    case multipleDiariesForDay

    public var errorDescription: String? {
        switch self {
        case .dayAlreadyOccupied:
            return "A diary already exists for this calendar day."
        case .multipleDiariesForDay:
            return "Multiple diaries exist for the same calendar day."
        }
    }
}
