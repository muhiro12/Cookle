@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

struct LegacySchemaMigrationTests {
    @Test
    func unversioned_store_without_photo_source_upgrades() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let url = directory.appendingPathComponent("default.store")
        try seed(at: url)
        #expect(throws: (any Error).self) {
            try ModelContainerFactory.makeReadOnlyContainer(url: url)
        }
        let container = try ModelContainerFactory.makeModelContainer(url: url)
        let context = ModelContext(container)
        let recipe = try #require(context.fetch(FetchDescriptor<Recipe>()).first)
        #expect(recipe.name == "Before versioned schemas")
        #expect(recipe.photos?.first?.data == Data([7, 8, 9]))
        #expect(recipe.photos?.first?.sourceID == PhotoSource.defaultValue.rawValue)
        #expect(recipe.photoObjects?.first?.photo === recipe.photos?.first)
        #expect(recipe.photoObjects?.first?.order == 2)
    }

    private func seed(at url: URL) throws {
        let container = try ModelContainer(
            for: Schema(ReleasedSchemaV0.models),
            configurations: .init(url: url, cloudKitDatabase: .none)
        )
        let context = ModelContext(container)
        let recipe = ReleasedSchemaV0.Recipe()
        context.insert(recipe)
        recipe.name = "Before versioned schemas"
        let photo = ReleasedSchemaV0.Photo()
        photo.data = Data([7, 8, 9])
        let row = ReleasedSchemaV0.PhotoObject()
        row.photo = photo
        row.order = 2
        recipe.photos = [photo]
        recipe.photoObjects = [row]
        try context.save()
    }
}
