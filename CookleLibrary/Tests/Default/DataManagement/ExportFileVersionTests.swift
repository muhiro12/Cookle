@testable import CookleLibrary
import Foundation
import ImageIO
import SwiftData
import Testing
import UniformTypeIdentifiers

// An export file carries two version numbers with separate jobs:
//
// | Field           | Now     | Versions                                   |
// | --------------- | ------- | ------------------------------------------ |
// | `formatVersion` | 1       | the package layout and manifest envelope   |
// | `schemaVersion` | "1.0.0" | the records, one-to-one with SwiftData     |
//
// Records follow the persistent schema that wrote them, so every schema in
// `CookleMigrationPlan.schemas` must stay readable, and a file from a newer
// schema is reported as needing a newer Cookle rather than as damaged.
@MainActor
struct ExportFileVersionTests {
    private typealias Support = CookleDataArchivePackageTestSupport
    private typealias PackageError = CookleDataArchivePackageError

    @Test
    func a_package_declares_its_format_schema_and_complete_scope() throws {
        let manifest = try Support.manifest(from: Support.package())

        #expect(manifest.format == "com.muhiro12.cookle.data")
        #expect(manifest.formatVersion == Value.formatVersion)
        #expect(manifest.schemaVersion == "1.0.0")
        #expect(manifest.contents.scope == "all")
        #expect(
            manifest.schemaVersion
                == CookleDataArchiveSchemaVersions.string(
                    for: CookleMigrationPlan.currentSchema.versionIdentifier
                )
        )
    }

    @Test
    func every_released_schema_stays_readable() {
        // A key path over `any VersionedSchema.Type` crashes SILGen in the current
        // toolchain, so the versions are collected without one.
        var releasedVersions = [Schema.Version]()
        for schema in CookleMigrationPlan.schemas {
            releasedVersions.append(schema.versionIdentifier)
        }

        #expect(CookleDataArchiveSchemaVersions.readable == releasedVersions)
    }

    @Test
    func a_newer_schema_asks_for_a_newer_cookle() throws {
        let package = try Support.package()
        let newerPackage = try Support.package(
            manifest: Support.replacingHeader(
                Support.manifest(from: package),
                schemaVersion: "99.0.0"
            ),
            photoFiles: package.photoFiles
        )

        #expect(throws: CookleDataArchiveVersionError.newerSchemaVersion("99.0.0")) {
            try DataMaintenanceOperations.validatedArchive(
                from: newerPackage,
                calendar: Support.calendar
            )
        }
    }

    @Test(arguments: InvalidHeader.allCases)
    func an_invalid_header_is_rejected(
        _ header: InvalidHeader
    ) throws {
        let package = try Support.package()
        let manifest = try Support.manifest(from: package)
        let invalidPackage = try Support.package(
            manifest: header.applied(to: manifest),
            photoFiles: package.photoFiles
        )

        do {
            _ = try DataMaintenanceOperations.validatedArchive(
                from: invalidPackage,
                calendar: Support.calendar
            )
            Issue.record("Expected \(header) to be rejected.")
        } catch let error as PackageError {
            #expect(header.matches(error))
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func an_unknown_scope_is_read_as_a_partial_file() throws {
        let package = try Support.package()
        let partialPackage = try Support.package(
            manifest: Support.replacingHeader(
                Support.manifest(from: package),
                scope: "selectedRecipes"
            ),
            photoFiles: package.photoFiles
        )

        let archive = try DataMaintenanceOperations.validatedArchive(
            from: partialPackage,
            calendar: Support.calendar
        )

        #expect(archive.scope == .partial("selectedRecipes"))
        #expect(archive.recipes.count == 1)
    }

    @Test
    func photo_filenames_name_the_image_type_and_round_trip() throws {
        let jpeg = try #require(Value.jpegData)
        let package = try Support.package(
            photoPayloads: [
                jpeg,
                Support.photoData
            ],
            limits: ArchiveResourceLimitTestSupport.makeLimits(
                maximumPhotoByteCount: Value.photoByteLimit,
                maximumAggregatePhotoByteCount: Value.photoByteLimit
            )
        )
        let manifest = try Support.manifest(from: package)

        #expect(manifest.photos.map(\.filename) == ["photo-000001.jpeg", "photo-000002.data"])
        #expect(package.photoFiles.map(\.filename) == ["photo-000001.jpeg", "photo-000002.data"])

        let archive = try CookleDataArchiveService.validatedArchive(
            from: package,
            calendar: Support.calendar,
            limits: ArchiveResourceLimitTestSupport.makeLimits(
                maximumPhotoByteCount: Value.photoByteLimit,
                maximumAggregatePhotoByteCount: Value.photoByteLimit
            )
        )
        #expect(archive.photos.map(\.data) == [jpeg, Support.photoData])
    }

    @Test
    func schema_version_text_needs_three_plain_numbers() {
        #expect(CookleDataArchiveSchemaVersions.version(from: "1.0.0") == Schema.Version(1, .zero, .zero))
        #expect(CookleDataArchiveSchemaVersions.version(from: "12.3.45") == Value.multiDigitVersion)
        #expect(CookleDataArchiveSchemaVersions.version(from: "1.0") == nil)
        #expect(CookleDataArchiveSchemaVersions.version(from: "1.0.0.0") == nil)
        #expect(CookleDataArchiveSchemaVersions.version(from: "+1.0.0") == nil)
        #expect(CookleDataArchiveSchemaVersions.version(from: "1..0") == nil)
        #expect(CookleDataArchiveSchemaVersions.version(from: "v1.0.0") == nil)
    }
}

extension ExportFileVersionTests {
    enum InvalidHeader: CaseIterable, CustomStringConvertible {
        case otherFormat
        case otherFormatVersion
        case malformedSchemaVersion

        var description: String {
            switch self {
            case .otherFormat:
                "another format"
            case .otherFormatVersion:
                "another format version"
            case .malformedSchemaVersion:
                "a malformed schema version"
            }
        }

        func applied(
            to manifest: CookleDataArchivePackageManifest
        ) -> CookleDataArchivePackageManifest {
            switch self {
            case .otherFormat:
                CookleDataArchivePackageTestSupport.replacingHeader(
                    manifest,
                    format: "com.muhiro12.cookle.backup"
                )
            case .otherFormatVersion:
                CookleDataArchivePackageTestSupport.replacingHeader(
                    manifest,
                    formatVersion: Value.unsupportedFormatVersion
                )
            case .malformedSchemaVersion:
                CookleDataArchivePackageTestSupport.replacingHeader(
                    manifest,
                    schemaVersion: "one"
                )
            }
        }

        func matches(
            _ error: CookleDataArchivePackageError
        ) -> Bool {
            switch (self, error) {
            case (.otherFormat, .unsupportedFormat("com.muhiro12.cookle.backup")),
                 (.otherFormatVersion, .unsupportedFormatVersion(Value.unsupportedFormatVersion)),
                 (.malformedSchemaVersion, .unsupportedSchemaVersion("one")):
                true
            default:
                false
            }
        }
    }
}

private extension ExportFileVersionTests {
    enum MultiDigitVersion {
        static let major = 12
        static let minor = 3
        static let patch = 45
    }

    enum Pixel {
        static let byteCount = 4
        static let bitsPerComponent = 8
    }

    enum Value {
        static let formatVersion = 1
        static let unsupportedFormatVersion = 2
        static let photoByteLimit = 4_096
        static var multiDigitVersion: Schema.Version {
            .init(MultiDigitVersion.major, MultiDigitVersion.minor, MultiDigitVersion.patch)
        }
        /// A 1x1 JPEG written by ImageIO, so its type is identified the same way.
        static var jpegData: Data? {
            let pixel = [UInt8](
                repeating: .max,
                count: Pixel.byteCount
            )
            guard let provider = CGDataProvider(data: Data(pixel) as CFData),
                  let image = CGImage(
                    width: 1,
                    height: 1,
                    bitsPerComponent: Pixel.bitsPerComponent,
                    bitsPerPixel: Pixel.bitsPerComponent * Pixel.byteCount,
                    bytesPerRow: Pixel.byteCount,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: .init(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                    provider: provider,
                    decode: nil,
                    shouldInterpolate: false,
                    intent: .defaultIntent
                  ) else {
                return nil
            }
            let data = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                data as CFMutableData,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            ) else {
                return nil
            }
            CGImageDestinationAddImage(destination, image, nil)
            guard CGImageDestinationFinalize(destination) else {
                return nil
            }
            return data as Data
        }
    }
}
