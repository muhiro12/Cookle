import Foundation

/// Error surfaced when a quick recipe version cannot be produced safely.
public enum QuickRecipeVersionError: LocalizedError, Equatable, Sendable {
    case emptySteps
    case insufficientContent

    public var errorDescription: String? {
        switch self {
        case .emptySteps:
            return "This recipe needs steps before Cookle can make a quick version."
        case .insufficientContent:
            return "Couldn't create a useful quick version for this recipe."
        }
    }
}
