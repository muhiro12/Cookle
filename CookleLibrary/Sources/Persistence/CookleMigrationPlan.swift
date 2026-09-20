import SwiftData

/// Ordered history of Cookle's persistent schemas.
public enum CookleMigrationPlan: SchemaMigrationPlan {
    /// Schema used by all current app and extension containers.
    public static var currentSchema: any VersionedSchema.Type {
        CookleSchemaV1.self
    }

    public static var schemas: [any VersionedSchema.Type] {
        [CookleSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}
