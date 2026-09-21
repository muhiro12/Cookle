@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

// Cookle carries three independent version numbers, and they are easy to
// confuse because their current values do not line up:
//
// | Number                                                  | Now   | Versions              |
// | ------------------------------------------------------- | ----- | --------------------- |
// | `CookleDataArchive.currentFormatVersion`                 | 1     | the JSON record shape |
// | `CookleDataArchivePackageManifest.currentPackageFormatVersion` | 2 | the package container |
// | `CookleSchemaV1.versionIdentifier`                       | 1.0.0 | the on-disk store     |
//
// A package therefore declares "version 2" while carrying "version 1" records
// into a "1.0.0" store. These tests pin the three values and the fact that a
// package is validated against two of them independently, so that changing one
// forces a deliberate look at the others rather than a silent mismatch.
@MainActor
struct ArchiveVersionAxesTests {
    private typealias Support = CookleDataArchivePackageTestSupport
    private typealias PackageError = CookleDataArchivePackageError

    @Test
    func the_three_version_numbers_are_what_the_formats_document() {
        #expect(CookleDataArchive.currentFormatVersion == Value.archiveFormatVersion)
        #expect(
            CookleDataArchivePackageManifest.currentPackageFormatVersion
                == Value.packageFormatVersion
        )
        #expect(
            CookleSchemaV1.versionIdentifier
                == Schema.Version(Value.schemaMajor, .zero, .zero)
        )

        // The container version is deliberately ahead of the record version.
        // If a change ever makes them equal, that is a coincidence, not a rule.
        #expect(
            CookleDataArchivePackageManifest.currentPackageFormatVersion
                != CookleDataArchive.currentFormatVersion
        )
    }

    @Test
    func a_package_is_rejected_for_a_bad_record_version_not_only_a_bad_container_version() throws {
        let package = try Support.package()
        let manifest = try Support.manifest(from: package)

        // Container version is current; only the record-shape version is wrong.
        let invalidPackage = try Support.package(
            manifest: Support.replacingArchiveFormatVersion(
                manifest,
                with: Value.unsupportedVersion
            ),
            photoFiles: package.photoFiles
        )

        do {
            _ = try DataMaintenanceOperations.validatedArchive(
                from: invalidPackage,
                calendar: Support.calendar
            )
            Issue.record("Expected the archive format version to be rejected.")
        } catch CookleDataArchiveService.ArchiveError.unsupportedFormatVersion(let version) {
            // Not `PackageError`: the two axes report through different errors.
            #expect(version == Value.unsupportedVersion)
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func a_current_package_round_trips_through_both_axes() throws {
        let package = try Support.package()
        let manifest = try Support.manifest(from: package)

        #expect(
            manifest.packageFormatVersion
                == CookleDataArchivePackageManifest.currentPackageFormatVersion
        )
        #expect(
            manifest.archiveFormatVersion == CookleDataArchive.currentFormatVersion
        )

        let archive = try DataMaintenanceOperations.validatedArchive(
            from: package,
            calendar: Support.calendar
        )

        // The decoded archive carries the record-shape version, not the
        // container's.
        #expect(archive.formatVersion == CookleDataArchive.currentFormatVersion)
    }

    @Test
    func legacy_json_carries_no_package_version_and_still_restores() throws {
        // The pre-package export is bare JSON: one version number, no manifest
        // and no external photo files.
        let archive = try DataMaintenanceOperations.validatedArchive(
            from: Support.legacyArchiveData,
            calendar: Support.calendar
        )

        #expect(archive.formatVersion == CookleDataArchive.currentFormatVersion)
        #expect(archive.photos.count == 1)
        #expect(archive.photos.first?.data == Support.photoData)
    }
}

private extension ArchiveVersionAxesTests {
    enum Value {
        static let archiveFormatVersion = 1
        static let packageFormatVersion = 2
        static let schemaMajor = 1
        static let unsupportedVersion = 99
    }
}
