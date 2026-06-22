import Foundation

/// Created and modified timestamps restored for persisted models.
public struct PersistentTimestamps: Equatable, Sendable {
    public var created: Date
    public var modified: Date

    public init(
        created: Date,
        modified: Date
    ) {
        self.created = created
        self.modified = modified
    }
}
