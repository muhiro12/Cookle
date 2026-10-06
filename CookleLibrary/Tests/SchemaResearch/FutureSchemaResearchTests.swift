@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

/// Synthetic compatibility observations; passing does not establish data-loss safety.
@MainActor
@Suite(.serialized)
struct FutureSchemaResearchTests {
    // The shape a user produces by running a build with a newer schema and then
    // going back to the released one. Cookle defines no downgrade stage, so the
    // question this pins is not whether the store upgrades — it is whether the
    // released build destroys what the newer build wrote.
    @Test
    func opening_a_store_from_a_newer_schema_keeps_the_shared_records() throws {
        try withDirectory { directory in
            let url = directory.appendingPathComponent("default.store")
            try seedFutureStore(at: url)

            let container = try ModelContainerFactory.makeModelContainer(
                url: url,
                cloudKitDatabase: .none
            )
            let context = ModelContext(container)

            // The released build opens it rather than refusing, and the records
            // whose shape both schemas share are still there.
            #expect(try context.fetch(.recipes(.all)).map(\.name) == ["Curry"])
            #expect(FileManager.default.fileExists(atPath: url.path))
        }
    }

    // Measured, not assumed: the released build does not refuse a newer store,
    // and records only the newer schema knew about do not come back. Pinned so
    // that a change in either direction is visible.
    @Test
    func a_newer_schemas_own_records_are_lost_once_the_released_build_writes() throws {
        try withDirectory { directory in
            let url = directory.appendingPathComponent("default.store")
            try seedFutureStore(at: url)

            // Open, write, and close with the released schema, the way a
            // downgraded install would.
            let released = try ModelContainerFactory.makeModelContainer(
                url: url,
                cloudKitDatabase: .none
            )
            let releasedContext = ModelContext(released)
            releasedContext.autosaveEnabled = false
            _ = Recipe.create(context: releasedContext, content: Self.saladContent)
            try releasedContext.save()

            // Then reopen with the newer schema, the way reinstalling the newer
            // build would.
            let future = try ModelContainer(
                for: .init(versionedSchema: FutureSchemaV2.self),
                configurations: .init(url: url, cloudKitDatabase: .none)
            )
            let futureContext = ModelContext(future)
            let notes = try futureContext.fetch(
                FetchDescriptor<FutureSchemaV2.FutureNote>()
            )

            // The newer schema's own entity is empty: opening with the released
            // schema dropped what it did not know about, without an error and
            // without a prompt.
            #expect(notes.isEmpty)
            // Everything both schemas share survived, including the row the
            // released build added.
            #expect(
                try futureContext.fetch(FetchDescriptor<Recipe>())
                    .map(\.name)
                    .sorted() == ["Curry", "Salad"]
            )
        }
    }
}

private extension FutureSchemaResearchTests {
    enum Value {
        static let cookingTime = 10
    }

    static var curryContent: RecipeContent {
        content(name: "Curry")
    }

    static var saladContent: RecipeContent {
        content(name: "Salad")
    }

    static func content(name: String) -> RecipeContent {
        .init(
            name: name,
            photos: [],
            servingSize: 1,
            cookingTime: Value.cookingTime,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
    }

    func withDirectory(_ body: (URL) throws -> Void) throws {
        let directory = try persistentTestDirectory(fileManager: .default)
        try body(directory)
    }

    func seedFutureStore(at url: URL) throws {
        try #require(FutureSchemaV2.versionIdentifier > CookleMigrationPlan.currentSchema.versionIdentifier)
        let container = try ModelContainer(
            for: .init(versionedSchema: FutureSchemaV2.self),
            configurations: .init(url: url, cloudKitDatabase: .none)
        )
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let note = FutureSchemaV2.FutureNote()
        context.insert(note)
        note.body = "written by a newer build"
        _ = Recipe.create(context: context, content: Self.curryContent)
        try context.save()
    }
}
