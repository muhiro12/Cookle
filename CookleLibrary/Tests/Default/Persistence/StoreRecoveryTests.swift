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
    enum Value {
        static let cookingTime = 10
    }

    static var curryContent: RecipeContent {
        content(name: "Curry")
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
