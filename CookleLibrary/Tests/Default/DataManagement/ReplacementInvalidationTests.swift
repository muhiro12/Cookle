@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

// A replacement inserts every record anew rather than updating in place, so anything
// holding a reference from before it — an open detail screen, a route, a
// cooking session snapshot — is pointing at something that no longer exists.
//
// `CookingSessionSnapshot.recipeID` is a stable identifier string, so these
// tests measure whether such a reference survives a replacement that contains the
// very same recipe. It does not, and that is what a surface has to handle.
@MainActor
struct ReplacementInvalidationTests {
    private typealias Support = CookleDataArchivePackageTestSupport

    @Test
    func a_stable_identifier_does_not_survive_a_replacement_of_the_same_content() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            _ = try DataMaintenanceOperations.replaceAllData(
                with: Support.archive(),
                context: context
            )

            let before = try #require(try context.fetch(.recipes(.all)).first)
            let beforeIdentifier = RecipeStableIdentifierCodec.stableIdentifier(for: before)
            #expect(before.name == "Pancakes")

            // Replace with the identical archive again, the way re-importing the
            // same export file would.
            _ = try DataMaintenanceOperations.replaceAllData(
                with: Support.archive(),
                context: context
            )

            let reopened = try makeContext(at: url)
            let after = try #require(try reopened.fetch(.recipes(.all)).first)

            // Same recipe by content...
            #expect(after.name == "Pancakes")
            // ...but the reference anything was holding is now dangling.
            #expect(
                try RecipeStableIdentifierCodec.recipe(
                    from: beforeIdentifier,
                    context: reopened
                ) == nil
            )
            #expect(
                RecipeStableIdentifierCodec.stableIdentifier(for: after) != beforeIdentifier
            )
        }
    }

    @Test
    func a_cooking_snapshot_taken_before_a_replacement_no_longer_resolves() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            _ = try DataMaintenanceOperations.replaceAllData(
                with: Support.archive(),
                context: context
            )
            let recipe = try #require(try context.fetch(.recipes(.all)).first)

            // The identifier a live cooking session would be carrying.
            let snapshotRecipeID = RecipeStableIdentifierCodec.stableIdentifier(for: recipe)

            _ = try DataMaintenanceOperations.replaceAllData(
                with: Support.archive(),
                context: context
            )

            let reopened = try makeContext(at: url)
            #expect(
                try RecipeStableIdentifierCodec.recipe(
                    from: snapshotRecipeID,
                    context: reopened
                ) == nil
            )
            // The store is not empty — the session is orphaned, not the data.
            #expect(try reopened.fetch(.recipes(.all)).isEmpty == false)
        }
    }

    @Test
    func a_replacement_leaves_exactly_the_archive_contents_not_a_merge() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            _ = try DataMaintenanceOperations.replaceAllData(
                with: Support.archive(),
                context: context
            )
            _ = Recipe.create(
                context: context,
                content: .init(
                    name: "AddedAfterExport",
                    photos: [],
                    servingSize: Value.servingSize,
                    cookingTime: Value.cookingTimeMinutes,
                    ingredients: [],
                    steps: [],
                    categories: [],
                    note: ""
                )
            )
            try context.save()
            #expect(try context.fetch(.recipes(.all)).count == 2)

            _ = try DataMaintenanceOperations.replaceAllData(
                with: Support.archive(),
                context: context
            )

            // Replacement, not merge: the record added after the export is gone.
            let reopened = try makeContext(at: url)
            let names = try reopened.fetch(.recipes(.all)).map(\.name)
            #expect(names == ["Pancakes"])
        }
    }
}

private extension ReplacementInvalidationTests {
    enum Value {
        static let servingSize = 1
        static let cookingTimeMinutes = 10
    }

    func withDiskStore(_ body: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        try body(directory.appendingPathComponent("store.sqlite"))
    }

    func makeContext(at url: URL) throws -> ModelContext {
        let container = try ModelContainerFactory.makeModelContainer(
            url: url,
            cloudKitDatabase: .none
        )
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }
}
