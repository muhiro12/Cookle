import Foundation

/// Approval tied to all current data and the incoming complete-library file.
/// Rebuild the review after a change and ask for confirmation before replacing.
public struct CookleDataReplacementReview: Equatable, Sendable {
    let archiveIdentity: Data
    let currentDataIdentity: Data
}
