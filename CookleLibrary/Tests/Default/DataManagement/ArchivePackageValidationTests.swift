@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct ArchivePackageValidationTests {
    private typealias PackageError = CookleDataArchivePackageError
    private typealias Support = CookleDataArchivePackageTestSupport

    @Test
    func validatedArchive_rejects_unsupported_package_version() throws {
        let package = try Support.package()
        let manifest = try Support.manifest(
            from: package
        )
        let invalidPackage = try Support.package(
            manifest: Support.replacingPackageFormatVersion(
                manifest,
                with: 99
            ),
            photoFiles: package.photoFiles
        )

        do {
            _ = try DataMaintenanceOperations.validatedArchive(
                from: invalidPackage,
                calendar: Support.calendar
            )
            Issue.record("Expected package version validation to fail.")
        } catch PackageError.unsupportedPackageFormatVersion(let version) {
            #expect(version == 99)
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_rejects_invalid_photo_filename() throws {
        let package = try Support.package()
        let invalidPackage: CookleDataArchivePackage = .init(
            manifestData: package.manifestData,
            photoFiles: [
                .init(
                    filename: "../photo.data",
                    data: Support.photoData
                )
            ]
        )

        do {
            _ = try DataMaintenanceOperations.validatedArchive(
                from: invalidPackage,
                calendar: Support.calendar
            )
            Issue.record("Expected photo filename validation to fail.")
        } catch PackageError.invalidPhotoFilename(let filename) {
            #expect(filename == "../photo.data")
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_rejects_duplicate_photo_filename() throws {
        let package = try Support.package()
        let photoFile = try #require(
            package.photoFiles.first
        )
        let invalidPackage: CookleDataArchivePackage = .init(
            manifestData: package.manifestData,
            photoFiles: [
                photoFile,
                photoFile
            ]
        )

        do {
            _ = try CookleDataArchivePackageCodec.validatedArchive(
                from: invalidPackage,
                calendar: Support.calendar,
                limits: ArchiveResourceLimitTestSupport.makeLimits()
            )
            Issue.record("Expected duplicate photo filename validation to fail.")
        } catch PackageError.duplicatePhotoFilename(let filename) {
            #expect(filename == "photo-000001.data")
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_rejects_missing_and_unexpected_photo_files() throws {
        let package = try Support.package()
        let missingPackage: CookleDataArchivePackage = .init(
            manifestData: package.manifestData,
            photoFiles: []
        )

        do {
            _ = try DataMaintenanceOperations.validatedArchive(
                from: missingPackage,
                calendar: Support.calendar
            )
            Issue.record("Expected missing photo validation to fail.")
        } catch PackageError.missingPhotoFile(let filename) {
            #expect(filename == "photo-000001.data")
        } catch {
            Issue.record(error)
        }

        let unexpectedPackage: CookleDataArchivePackage = .init(
            manifestData: package.manifestData,
            photoFiles: package.photoFiles + [
                .init(
                    filename: "photo-000002.data",
                    data: Data()
                )
            ]
        )
        do {
            _ = try DataMaintenanceOperations.validatedArchive(
                from: unexpectedPackage,
                calendar: Support.calendar
            )
            Issue.record("Expected unexpected photo validation to fail.")
        } catch PackageError.unexpectedPhotoFile(let filename) {
            #expect(filename == "photo-000002.data")
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_rejects_photo_byte_count_mismatch() throws {
        let package = try Support.package()
        let photoFile = try #require(
            package.photoFiles.first
        )
        let invalidPackage: CookleDataArchivePackage = .init(
            manifestData: package.manifestData,
            photoFiles: [
                .init(
                    filename: photoFile.filename,
                    data: photoFile.data + Data([5])
                )
            ]
        )

        do {
            _ = try DataMaintenanceOperations.validatedArchive(
                from: invalidPackage,
                calendar: Support.calendar
            )
            Issue.record("Expected photo byte count validation to fail.")
        } catch let PackageError.photoByteCountMismatch(
            filename,
            expectedByteCount,
            actualByteCount
        ) {
            #expect(filename == "photo-000001.data")
            #expect(expectedByteCount == Support.photoData.count)
            #expect(actualByteCount == Support.photoData.count + 1)
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_rejects_same_length_photo_digest_mismatch() throws {
        let package = try Support.package()
        let photoFile = try #require(
            package.photoFiles.first
        )
        let invalidPackage: CookleDataArchivePackage = .init(
            manifestData: package.manifestData,
            photoFiles: [
                .init(
                    filename: photoFile.filename,
                    data: Data([
                        4,
                        3,
                        2,
                        1
                    ])
                )
            ]
        )

        do {
            _ = try DataMaintenanceOperations.validatedArchive(
                from: invalidPackage,
                calendar: Support.calendar
            )
            Issue.record("Expected photo digest validation to fail.")
        } catch PackageError.photoDigestMismatch(let filename) {
            #expect(filename == "photo-000001.data")
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_rejects_malformed_photo_digest() throws {
        let package = try Support.package()
        let manifest = try Support.manifest(
            from: package
        )
        let photo = try #require(
            manifest.photos.first
        )
        let invalidPhoto: CookleDataArchivePackageManifest.PhotoRecord = .init(
            id: photo.id,
            filename: photo.filename,
            byteCount: photo.byteCount,
            sha256: String(photo.sha256.dropLast()) + "G",
            sourceID: photo.sourceID,
            createdTimestamp: photo.createdTimestamp,
            modifiedTimestamp: photo.modifiedTimestamp
        )
        let invalidPackage = try Support.package(
            manifest: Support.replacingPhotos(
                manifest,
                with: [
                    invalidPhoto
                ]
            ),
            photoFiles: package.photoFiles
        )

        do {
            _ = try DataMaintenanceOperations.validatedArchive(
                from: invalidPackage,
                calendar: Support.calendar
            )
            Issue.record("Expected photo digest format validation to fail.")
        } catch PackageError.invalidPhotoDigest(let filename) {
            #expect(filename == "photo-000001.data")
        } catch {
            Issue.record(error)
        }
    }
}
