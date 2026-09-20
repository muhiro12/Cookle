@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

/// Covers the photo and relationship details a whole-archive comparison can miss.
///
/// `ArchivePersistentStoreTests` proves the complete graph round-trips, but its
/// fixture carries one photo, one order, and a placeholder source string that is
/// not a real `PhotoSource` raw value. These tests drive the cases a user can
/// actually produce: photos from both sources, a non-trivial display order, and
/// an asset no recipe references.
@MainActor
struct ArchivePhotoFidelityTests {
    /// Pins the three version numbers a backup involves, which are unrelated.
    ///
    /// They are easy to confuse because two of them currently read `1`:
    ///
    /// - `CookleDataArchive.currentFormatVersion` (`1`) versions the **archive
    ///   payload** — the record shapes inside a backup.
    /// - `CookleDataArchivePackageManifest.currentPackageFormatVersion` (`2`)
    ///   versions the **container** that carries a manifest plus photo files
    ///   beside it. Version 1 was the single JSON blob, still readable.
    /// - `CookleSchemaV1.versionIdentifier` (`1.0.0`) versions the **SwiftData
    ///   store**, and has nothing to do with either.
    ///
    /// Nothing derives one from another. A schema change does not require an
    /// archive format bump, and an archive format bump does not migrate a store.
    @Test
    func the_three_backup_related_versions_are_independent() {
        #expect(CookleDataArchive.currentFormatVersion == 1)
        #expect(CookleDataArchivePackageManifest.currentPackageFormatVersion == 2)
        #expect(CookleSchemaV1.versionIdentifier == .init(1, 0, 0))
    }

    @Test
    func restoring_keeps_each_photos_own_source() throws {
        try withStore { url in
            try restore(Self.archiveWithBothSources(), at: url)

            let exported = try CookleDataArchiveService.makeArchive(
                context: try makeContext(at: url)
            )
            let sourcesByData = Dictionary(
                uniqueKeysWithValues: exported.photos.map { photo in
                    (photo.data, photo.sourceID)
                }
            )

            // A photo produced by Image Playground must not come back labelled
            // as a Photos pick, which is what a fallback to `defaultValue` would
            // silently do.
            #expect(sourcesByData[Self.pickedData] == PhotoSource.photosPicker.rawValue)
            #expect(
                sourcesByData[Self.generatedData] == PhotoSource.imagePlayground.rawValue
            )
        }
    }

    @Test
    func restoring_keeps_the_display_order_of_a_recipes_photos() throws {
        try withStore { url in
            try restore(Self.archiveWithOrderedPhotos(), at: url)

            let context = try makeContext(at: url)
            let recipe = try #require(try context.fetch(.recipes(.all)).first)
            let rows = (recipe.photoObjects ?? []).sorted { $0.order < $1.order }

            // The archive lists the rows in a different sequence from their
            // `order`, so this fails if restore replays list position instead of
            // the stored order.
            #expect(rows.map(\.order) == [1, 2, 3])
            #expect(
                rows.map { $0.photo?.data } == [Self.firstData, Self.secondData, Self.thirdData]
            )
        }
    }

    @Test
    func restoring_keeps_a_photo_no_recipe_references() throws {
        try withStore { url in
            try restore(Self.archiveWithUnlinkedPhoto(), at: url)

            let context = try makeContext(at: url)
            let photos = try context.fetch(FetchDescriptor<Photo>())
            let unlinked = try #require(
                photos.first { $0.data == Self.generatedData }
            )

            // Unlinked assets are never collected, so a backup has to carry them
            // and a restore has to put them back — otherwise a round trip
            // quietly prunes the user's library.
            #expect(photos.count == 2)
            #expect((unlinked.objects ?? []).isEmpty)
            #expect(unlinked.sourceID == PhotoSource.imagePlayground.rawValue)

            let exported = try CookleDataArchiveService.makeArchive(context: context)
            #expect(exported.photos.count == 2)
        }
    }
}

private extension ArchivePhotoFidelityTests {
    static let pickedData = Data("picked".utf8)
    static let generatedData = Data("generated".utf8)
    static let firstData = Data("first".utf8)
    static let secondData = Data("second".utf8)
    static let thirdData = Data("third".utf8)
    static let timestamp = Date(timeIntervalSince1970: 1_700_000_000)

    static func archiveWithBothSources() -> CookleDataArchive {
        let photos = [
            photoRecord(id: "picked", data: pickedData, source: .photosPicker),
            photoRecord(id: "generated", data: generatedData, source: .imagePlayground)
        ]
        return archive(
            photos: photos,
            recipePhotos: photos.enumerated().map { index, photo in
                recipePhotoRecord(photoID: photo.id, order: index + 1)
            }
        )
    }

    static func archiveWithOrderedPhotos() -> CookleDataArchive {
        let photos = [
            photoRecord(id: "first", data: firstData, source: .photosPicker),
            photoRecord(id: "second", data: secondData, source: .photosPicker),
            photoRecord(id: "third", data: thirdData, source: .photosPicker)
        ]
        return archive(
            photos: photos,
            // Listed out of sequence on purpose; `order` is the contract.
            recipePhotos: [
                recipePhotoRecord(photoID: "third", order: 3),
                recipePhotoRecord(photoID: "first", order: 1),
                recipePhotoRecord(photoID: "second", order: 2)
            ]
        )
    }

    static func archiveWithUnlinkedPhoto() -> CookleDataArchive {
        archive(
            photos: [
                photoRecord(id: "picked", data: pickedData, source: .photosPicker),
                photoRecord(id: "generated", data: generatedData, source: .imagePlayground)
            ],
            recipePhotos: [
                recipePhotoRecord(photoID: "picked", order: 1)
            ]
        )
    }

    static func archive(
        photos: [CookleDataArchive.PhotoRecord],
        recipePhotos: [CookleDataArchive.RecipePhotoRecord]
    ) -> CookleDataArchive {
        .init(
            formatVersion: CookleDataArchive.currentFormatVersion,
            exportedAt: timestamp,
            ingredients: [],
            categories: [],
            photos: photos,
            recipes: [
                .init(
                    id: "recipe",
                    name: "Curry",
                    photos: recipePhotos,
                    servingSize: 2,
                    cookingTime: 30,
                    ingredients: [],
                    steps: [],
                    categoryIDs: [],
                    note: "",
                    createdTimestamp: timestamp,
                    modifiedTimestamp: timestamp
                )
            ],
            diaries: []
        )
    }

    static func photoRecord(
        id: String,
        data: Data,
        source: PhotoSource
    ) -> CookleDataArchive.PhotoRecord {
        .init(
            id: id,
            data: data,
            sourceID: source.rawValue,
            createdTimestamp: timestamp,
            modifiedTimestamp: timestamp
        )
    }

    static func recipePhotoRecord(
        photoID: String,
        order: Int
    ) -> CookleDataArchive.RecipePhotoRecord {
        .init(
            photoID: photoID,
            order: order,
            createdTimestamp: timestamp,
            modifiedTimestamp: timestamp
        )
    }

    func withStore(_ body: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
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

    func restore(_ archive: CookleDataArchive, at url: URL) throws {
        _ = try DataMaintenanceOperations.restore(
            archive,
            context: try makeContext(at: url)
        )
    }
}
