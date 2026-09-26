import Foundation

/// Why a reviewed destructive change was not applied.
///
/// Both cases leave the store untouched. Surfaces respond by telling the user
/// the record is gone, or by building a fresh review and asking again.
public enum ReviewedMutationError: Error, Equatable, Sendable {
    /// The record the review was built for no longer exists.
    case targetMissing
    /// The records the change would affect differ from the ones reviewed.
    case impactChanged
}

extension ReviewedMutationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .targetMissing:
            "The item no longer exists."
        case .impactChanged:
            "The affected items changed after they were reviewed."
        }
    }
}
