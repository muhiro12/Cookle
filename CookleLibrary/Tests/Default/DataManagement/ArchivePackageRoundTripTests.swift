@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct ArchivePackageRoundTripTests {
    private typealias Support = CookleDataArchivePackageTestSupport

    @Test
    func package_round_trip_preserves_archive_and_separates_photo_data() throws {
        let package = try Support.package()
        let archive = try DataMaintenanceOperations.validatedArchive(
            from: package,
            calendar: Support.calendar
        )
        let manifestObject = try #require(
            JSONSerialization.jsonObject(
                with: package.manifestData
            ) as? [String: Any]
        )
        let manifestPhotos = try #require(
            manifestObject["photos"] as? [[String: Any]]
        )
        let manifestPhoto = try #require(
            manifestPhotos.first
        )

        #expect(package.photoFiles.count == 1)
        #expect(package.photoFiles.first?.filename == "photo-000001.data")
        #expect(package.photoFiles.first?.data == Support.photoData)
        #expect(manifestPhoto["data"] == nil)
        #expect(manifestPhoto["filename"] as? String == "photo-000001.data")
        #expect(archive.exportedAt == Support.exportedAt)
        #expect(archive.photos.first?.data == Support.photoData)
        #expect(archive.photos.first?.sourceID == "photos-picker")
        #expect(archive.recipes.first?.photos.first?.photoID == "photo-1")
        #expect(archive.diaries.first?.objects.first?.recipeID == "recipe-1")
    }

    @Test
    func archivePackage_exports_current_context_through_public_operations() async throws {
        let context = makeTestContext()
        let photoObject = try PhotoObject.create(
            context: context,
            photoData: .init(
                data: Support.photoData,
                source: .photosPicker
            ),
            order: .zero
        )
        _ = Recipe.create(
            context: context,
            content: .init(
                name: "Pancakes",
                photos: [
                    photoObject
                ],
                servingSize: 2,
                cookingTime: 15,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
        try context.save()

        let package = try await DataMaintenanceOperations.archivePackage(
            from: context,
            calendar: Support.calendar
        )
        let archive = try DataMaintenanceOperations.validatedArchive(
            from: package,
            calendar: Support.calendar
        )

        #expect(archive.photos.map(\.data) == [Support.photoData])
        #expect(archive.recipes.first?.name == "Pancakes")
    }

    @Test
    func archivePackage_propagates_calling_task_cancellation() async {
        let context = makeTestContext()
        let exportTask = Task {
            try await DataMaintenanceOperations.archivePackage(
                from: context,
                calendar: Support.calendar
            )
        }
        exportTask.cancel()

        do {
            _ = try await exportTask.value
            Issue.record("Expected package export cancellation to propagate.")
        } catch is CancellationError {
            // Expected.
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func legacy_version_1_json_import_remains_compatible() throws {
        let archive = try DataMaintenanceOperations.validatedArchive(
            from: Support.legacyArchiveData,
            calendar: Support.calendar
        )

        #expect(archive.formatVersion == 1)
        #expect(archive.photos.map(\.data) == [Support.photoData])
    }
}
