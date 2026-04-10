import Foundation

enum MigrationValidationError: Equatable, LocalizedError {
    case persistedEntityCountMismatch(
            legacyObjectCounts: MigrationObjectCounts,
            currentObjectCounts: MigrationObjectCounts
         )

    var errorDescription: String? {
        switch self {
        case let .persistedEntityCountMismatch(
            legacyObjectCounts,
            currentObjectCounts
        ):
            return """
            Migrated store validation failed. \
            legacy[\(legacyObjectCounts.summary)] \
            current[\(currentObjectCounts.summary)]
            """
        }
    }
}
