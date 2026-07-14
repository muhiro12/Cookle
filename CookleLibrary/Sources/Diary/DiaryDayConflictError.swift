import Foundation

/// Errors raised when more than one diary would represent the same calendar day.
public enum DiaryDayConflictError: Equatable, LocalizedError, Sendable {
    /// Another diary already occupies the requested calendar day.
    case dayAlreadyOccupied

    public var errorDescription: String? {
        switch self {
        case .dayAlreadyOccupied:
            return "A diary already exists for this calendar day."
        }
    }
}
