@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct StoreOwnershipTests {
    @Test
    func extension_does_not_create_missing_store() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        #expect(throws: (any Error).self) {
            try ModelContainerFactory.makeReadOnlyContainer(url: url)
        }
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test
    func extension_reads_existing_store_but_cannot_save() throws {
        let directory = try makeDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let url = directory.appendingPathComponent("default.store")
        try seedDetachedRows(at: url)
        let container = try ModelContainerFactory.makeReadOnlyContainer(url: url)
        #expect(container.migrationPlan == nil)
        let context = ModelContext(container)
        #expect(try context.fetchCount(FetchDescriptor<IngredientObject>()) == 1)
        _ = try Ingredient.create(context: context, value: "Must not persist")
        #expect(throws: (any Error).self) {
            try context.save()
        }
        context.rollback()
    }

    @Test
    func app_startup_preserves_rows_with_missing_parents() throws {
        let directory = try makeDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let url = directory.appendingPathComponent("default.store")
        try seedDetachedRows(at: url)
        try openApp(at: url)
        let container = try ModelContainerFactory.makeReadOnlyContainer(url: url)
        let context = ModelContext(container)
        #expect(try context.fetchCount(FetchDescriptor<IngredientObject>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<PhotoObject>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<DiaryObject>()) == 1)
        let row = try #require(context.fetch(FetchDescriptor<IngredientObject>()).first)
        #expect(row.amount == "Preserve amount")
        #expect(row.ingredient?.value == "Salt")
    }

    @Test
    func relocation_preserves_both_populated_stores() throws {
        let directory = try makeDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let legacyURL = directory.appendingPathComponent("legacy.store")
        let currentURL = directory.appendingPathComponent("current.store")
        try seedDetachedRows(at: legacyURL)
        try seedDetachedRows(at: currentURL)
        let legacyBytes = try storedContent(at: legacyURL)
        let currentBytes = try storedContent(at: currentURL)
        #expect(throws: (any Error).self) {
            try ModelContainerFactory.makeAppContainer(
                legacyURL: legacyURL,
                currentURL: currentURL,
                cloudKitDatabase: .none
            )
        }
        #expect(try storedContent(at: legacyURL) == legacyBytes)
        #expect(try storedContent(at: currentURL) == currentBytes)
    }

    @Test
    func relocation_replaces_empty_destination_and_preserves_graph() throws {
        let directory = try makeDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let legacyDirectory = directory.appendingPathComponent("legacy")
        let currentDirectory = directory.appendingPathComponent("current")
        try FileManager.default.createDirectory(at: legacyDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let legacyURL = legacyDirectory.appendingPathComponent("default.store")
        let currentURL = currentDirectory.appendingPathComponent("default.store")
        try seedDetachedRows(at: legacyURL)
        let original = try storedContent(at: legacyURL)
        _ = try ModelContainerFactory.makeModelContainer(url: currentURL)
        _ = try ModelContainerFactory.makeAppContainer(
            legacyURL: legacyURL,
            currentURL: currentURL,
            cloudKitDatabase: .none
        )
        #expect(try storedContent(at: currentURL) == original)
        #expect(!FileManager.default.fileExists(atPath: legacyURL.path))
    }

    private func storedContent(at url: URL) throws -> Data {
        let container = try ModelContainerFactory.makeReadOnlyContainer(url: url)
        let archive = try CookleDataArchiveService.makeArchive(context: ModelContext(container))
        return try CookleDataArchiveService.encoder.encode(
            CookleDataArchive(
                formatVersion: archive.formatVersion,
                exportedAt: CookleDataArchivePackageTestSupport.exportedAt,
                ingredients: archive.ingredients,
                categories: archive.categories,
                photos: archive.photos,
                recipes: archive.recipes,
                diaries: archive.diaries
            )
        )
    }

    private func openApp(at url: URL) throws {
        _ = try ModelContainerFactory.makeAppContainer(
            legacyURL: url,
            currentURL: url,
            cloudKitDatabase: .none
        )
    }

    private func makeDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func seedDetachedRows(at url: URL) throws {
        let container = try ModelContainerFactory.makeModelContainer(url: url)
        let context = ModelContext(container)
        _ = try IngredientObject.create(context: context, ingredient: "Salt", amount: "Preserve amount", order: 1)
        _ = try PhotoObject.create(context: context, photoData: .init(data: Data([1]), source: .photosPicker), order: 1)
        let recipe = Recipe.create(
            context: context,
            content: .init(
                name: "Recipe",
                photos: [],
                servingSize: 2,
                cookingTime: 3,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
        _ = DiaryObject.create(context: context, recipe: recipe, type: .dinner, order: 1)
        try context.save()
    }
}
