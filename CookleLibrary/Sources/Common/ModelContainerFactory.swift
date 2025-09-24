import SwiftData

public enum ModelContainerFactory {
    public static func shared() throws -> ModelContainer {
        try ModelContainer(
            for: .init(versionedSchema: CookleMigrationPlan.schemas[0]),
            migrationPlan: CookleMigrationPlan.self,
            configurations: .init()
        )
    }

    public static func sharedContext() throws -> ModelContext {
        .init(try shared())
    }
}
