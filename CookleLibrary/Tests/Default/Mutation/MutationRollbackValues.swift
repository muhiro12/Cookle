import Foundation

/// Fixture values shared by the rollback persistence suites.
///
/// Kept in its own file because `MutationRollbackTestSupport` is a protocol,
/// and a protocol extension can hold neither a stored property nor a nested
/// type.
enum MutationRollbackValues {
    static let dayReference: TimeInterval = 800_000_000
    static let duplicateDayOffset: TimeInterval = 60
    static let servingSize = 1
    static let cookingTimeMinutes = 10
}
