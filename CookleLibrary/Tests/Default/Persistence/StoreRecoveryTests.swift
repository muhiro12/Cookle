@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

/// Pins that a store Cookle cannot open is left alone.
///
/// The upgrade path has one property that matters more than any other: when
/// something goes wrong, the only readable copy of the user's data must survive.
/// Startup surfaces the failure and offers a retry rather than starting fresh,
/// so these tests check the layer underneath — that the failing open, and the
/// validation that guards legacy cleanup, leave the files on disk untouched.
@MainActor
struct StoreRecoveryTests {
    @Test
    func opening_a_corrupt_store_throws_and_leaves_the_bytes_untouched() throws {
        try withDirectory { directory in
            let url = directory.appendingPathComponent("default.store")
            let corruptBytes = Data("not a sqlite file".utf8)
            try corruptBytes.write(to: url)

            #expect(throws: (any Error).self) {
                try ModelContainerFactory.makeModelContainer(url: url, cloudKitDatabase: .none)
            }
            #expect(try Data(contentsOf: url) == corruptBytes)
        }
    }

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

    @Test
    func failed_validation_keeps_the_legacy_store_on_disk() throws {
        try withDirectory { directory in
            let legacyURL = directory.appendingPathComponent("legacy.store")
            let currentURL = directory.appendingPathComponent("current.store")
            try seedCurrentStore(at: legacyURL)
            try Data("not a sqlite file".utf8).write(to: currentURL)

            // Validation runs before the legacy copy is deleted. A destination
            // it cannot open must abort cleanup, not proceed past it.
            #expect(throws: (any Error).self) {
                try ModelContainerFactory.validateMigratedDataBeforeDeletingLegacyIfNeeded(
                    currentStoreURL: currentURL,
                    cloudKitDatabase: .none,
                    legacyURL: legacyURL
                )
            }
            // Reopened rather than compared byte for byte: SQLite may checkpoint
            // the file after the seeding container closes, so the bytes are not
            // stable even when nothing was lost.
            let reopened = ModelContext(
                try ModelContainerFactory.makeModelContainer(
                    url: legacyURL,
                    cloudKitDatabase: .none
                )
            )
            #expect(try reopened.fetch(.recipes(.all)).map(\.name) == ["Curry"])
        }
    }
}

private extension StoreRecoveryTests {
    /// A schema Cookle has never released, standing in for a future version.
    enum FutureSchemaV2: VersionedSchema {
        @Model
        final class FutureNote {
            var body = ""

            init() {
                // Fixture values are assigned before saving.
            }
        }

        static var versionIdentifier: Schema.Version {
            .init(2, 0, 0)
        }

        static var models: [any PersistentModel.Type] {
            CookleSchemaV1.models + [FutureNote.self]
        }
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
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
    }

    func withDirectory(_ body: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        try body(directory)
    }

    func fileSize(of url: URL) throws -> Int {
        try Data(contentsOf: url).count
    }

    func seedFutureStore(at url: URL) throws {
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

    func seedCurrentStore(at url: URL) throws {
        let container = try ModelContainerFactory.makeModelContainer(
            url: url,
            cloudKitDatabase: .none
        )
        let context = ModelContext(container)
        context.autosaveEnabled = false
        _ = Recipe.create(context: context, content: Self.curryContent)
        try context.save()
    }
}
