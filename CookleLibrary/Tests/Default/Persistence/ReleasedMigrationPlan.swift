import SwiftData

enum ReleasedMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ReleasedSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
