import Foundation

enum MigrationValidationError: Equatable, LocalizedError {
    case recipeAndDiaryCountMismatch(
            legacyObjectCounts: MigrationObjectCounts,
            currentObjectCounts: MigrationObjectCounts
         )

    var errorDescription: String? {
        switch self {
        case let .recipeAndDiaryCountMismatch(
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
