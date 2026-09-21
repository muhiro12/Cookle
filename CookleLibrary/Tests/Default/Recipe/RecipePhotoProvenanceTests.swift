@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

// Pins where a photo's recorded origin lives and how long it survives.
//
// A recipe edit replaces every `PhotoObject` row, so the only thing carrying a
// generated photo's provenance across a save is the `Photo` asset itself. These
// record what that actually means, measured against a disk store rather than
// assumed: the label follows the shared asset, not the recipe, and every save
// rewrites it from whatever the caller supplied.
//
// Expectations were recorded from observed output. They set no quality
// threshold and need no model; that work needs the on-device model and a
// decision about what "good enough" means.
@MainActor
struct RecipePhotoProvenanceTests {
    @Test
    func an_edit_keeps_each_photo_label_and_renumbers_order_from_the_draft() throws {
        try withStore { context in
            let recipe = try makeRecipe(
                context: context,
                name: "Curry",
                photos: [
                    .init(data: Value.generated, source: .imagePlayground),
                    .init(data: Value.picked, source: .photosPicker)
                ]
            )

            #expect(orders(of: recipe) == [1, 2])
            #expect(sources(of: recipe) == [.imagePlayground, .photosPicker])

            // The app carries each photo's own source back into the draft, so
            // reversing the list must reverse the labels with it.
            try update(
                context: context,
                recipe: recipe,
                photos: carriedPhotos(of: recipe).reversed()
            )

            #expect(datas(of: recipe) == [Value.picked, Value.generated])
            #expect(sources(of: recipe) == [.photosPicker, .imagePlayground])
            // `order` is re-derived from array position, so it stays 1-based
            // and dense rather than following the rows that were replaced.
            #expect(orders(of: recipe) == [1, 2])
            #expect(try assetCount(context) == 2)
        }
    }

    @Test
    func a_save_that_drops_the_source_relabels_the_generated_photo() throws {
        try withStore { context in
            let recipe = try makeRecipe(
                context: context,
                name: "Curry",
                photos: [.init(data: Value.generated, source: .imagePlayground)]
            )
            #expect(sources(of: recipe) == [.imagePlayground])

            // A caller that rebuilds the draft without reading the existing
            // source sends the default instead. `Photo.create` assigns it
            // unconditionally, so the Image Playground origin is gone.
            try update(
                context: context,
                recipe: recipe,
                photos: [.init(data: Value.generated, source: .photosPicker)]
            )

            #expect(sources(of: recipe) == [.photosPicker])
            // No new asset was inserted, so nothing holds the old label.
            #expect(try assetCount(context) == 1)
        }
    }

    @Test
    func the_label_belongs_to_the_shared_asset_and_the_last_save_wins() throws {
        try withStore { context in
            let first = try makeRecipe(
                context: context,
                name: "Curry",
                photos: [.init(data: Value.generated, source: .imagePlayground)]
            )
            try update(
                context: context,
                recipe: first,
                photos: [.init(data: Value.generated, source: .photosPicker)]
            )
            #expect(sources(of: first) == [.photosPicker])

            // A second recipe reuses the same bytes and labels them again.
            let second = try makeRecipe(
                context: context,
                name: "Stew",
                photos: [.init(data: Value.generated, source: .imagePlayground)]
            )

            // One asset, one label. The second recipe did not get its own copy,
            // so its save reached back into what the first recipe displays.
            #expect(try assetCount(context) == 1)
            #expect(sources(of: second) == [.imagePlayground])
            #expect(sources(of: first) == [.imagePlayground])
        }
    }

    @Test
    func removing_a_photo_from_a_recipe_keeps_the_asset_and_its_label() throws {
        try withStore { context in
            let recipe = try makeRecipe(
                context: context,
                name: "Curry",
                photos: [
                    .init(data: Value.generated, source: .imagePlayground),
                    .init(data: Value.picked, source: .photosPicker)
                ]
            )
            let generatedRow = try #require(
                (recipe.photoObjects ?? []).first { $0.photo?.data == Value.generated }
            )

            _ = try RecipeService.removePhotoWithOutcome(
                context: context,
                recipe: recipe,
                photoObject: generatedRow
            )
            try context.save()

            #expect(datas(of: recipe) == [Value.picked])
            // The asset is unlinked, never deleted, and keeps its origin, so a
            // later recipe that reuses those bytes still finds the label.
            #expect(try assetCount(context) == 2)
            let generatedAsset = try #require(
                try context.fetch(FetchDescriptor<Photo>())
                    .first { $0.data == Value.generated }
            )
            #expect(generatedAsset.source == .imagePlayground)
        }
    }

    @Test
    func an_unrecognized_persisted_source_reads_as_the_default() throws {
        try withStore { context in
            let photo = Photo.restore(
                context: context,
                data: Value.generated,
                sourceID: "not-a-real-source",
                createdTimestamp: .now,
                modifiedTimestamp: .now
            )
            try context.save()

            // An archive from a future build, or a corrupted row, must not trap
            // or present an empty label.
            #expect(photo.source == .photosPicker)
            #expect(photo.sourceID == "not-a-real-source")
        }
    }
}

private extension RecipePhotoProvenanceTests {
    enum Value {
        static let generated = Data("generated".utf8)
        static let picked = Data("picked".utf8)
        static let servingSize = "2"
        static let cookingTime = "30"
    }

    func withStore(_ body: (ModelContext) throws -> Void) throws {
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
        let container = try ModelContainerFactory.makeModelContainer(
            url: directory.appendingPathComponent("store.sqlite"),
            cloudKitDatabase: .none
        )
        let context = ModelContext(container)
        context.autosaveEnabled = false
        try body(context)
    }

    func makeDraft(photos: [PhotoData], name: String) throws -> RecipeFormDraft {
        try RecipeFormOperations.makeDraft(
            input: .init(
                name: name,
                photos: photos,
                servingSize: Value.servingSize,
                cookingTime: Value.cookingTime,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
    }

    func makeRecipe(
        context: ModelContext,
        name: String,
        photos: [PhotoData]
    ) throws -> Recipe {
        let recipe = try RecipeFormOperations.createWithOutcome(
            context: context,
            draft: try makeDraft(photos: photos, name: name)
        ).value
        try context.save()
        return recipe
    }

    func update(
        context: ModelContext,
        recipe: Recipe,
        photos: [PhotoData]
    ) throws {
        _ = try RecipeFormOperations.updateWithOutcome(
            context: context,
            recipe: recipe,
            draft: try makeDraft(photos: photos, name: recipe.name)
        )
        try context.save()
    }

    /// Rebuilds draft input the way the form does, reading each existing
    /// asset's own source rather than assuming one.
    func carriedPhotos(of recipe: Recipe) -> [PhotoData] {
        rows(of: recipe).compactMap { object in
            guard let photo = object.photo else {
                return nil
            }
            return .init(data: photo.data, source: photo.source)
        }
    }

    func rows(of recipe: Recipe) -> [PhotoObject] {
        (recipe.photoObjects ?? []).sorted { $0.order < $1.order }
    }

    func orders(of recipe: Recipe) -> [Int] {
        rows(of: recipe).map(\.order)
    }

    func sources(of recipe: Recipe) -> [PhotoSource] {
        rows(of: recipe).compactMap { $0.photo?.source }
    }

    func datas(of recipe: Recipe) -> [Data] {
        rows(of: recipe).compactMap { $0.photo?.data }
    }

    func assetCount(_ context: ModelContext) throws -> Int {
        try context.fetch(FetchDescriptor<Photo>()).count
    }
}
