import Foundation

/// Errors thrown by tag workflows.
public enum TagServiceError: Equatable, LocalizedError {
    case emptyValue

    public var errorDescription: String? {
        switch self {
        case .emptyValue:
            return "Value must not be empty."
        }
    }
}
