@testable import CookleLibrary
import Foundation
import Testing

@MainActor
struct ArchivePackageResourceLimitTests {
    private typealias ArchiveError = CookleDataArchiveService.ArchiveError
    private typealias LimitSupport = ArchiveResourceLimitTestSupport
    private typealias PackageSupport = CookleDataArchivePackageTestSupport

    @Test
    func public_limits_preserve_legacy_capacity_and_support_long_term_photo_libraries() {
        let bytesPerMebibyte = 1_024 * 1_024

        #expect(
            DataMaintenanceOperations.maximumEncodedArchiveByteCount
                == 64 * bytesPerMebibyte
        )
        #expect(
            DataMaintenanceOperations.maximumArchiveManifestByteCount
                == 64 * bytesPerMebibyte
        )
        #expect(
            DataMaintenanceOperations.maximumArchivePhotoByteCount
                == 32 * bytesPerMebibyte
        )
        #expect(
            DataMaintenanceOperations.maximumArchiveAggregatePhotoByteCount
                == 256 * bytesPerMebibyte
        )
        #expect(
            DataMaintenanceOperations.maximumArchivePackageByteCount
                == 320 * bytesPerMebibyte
        )
    }

    @Test
    func validatedArchive_accepts_manifest_limit_and_rejects_one_byte_less() throws {
        let package = try PackageSupport.package()
        let exactLimits = LimitSupport.makeLimits(
            maximumManifestByteCount: package.manifestData.count
        )

        _ = try CookleDataArchivePackageCodec.validatedArchive(
            from: package,
            calendar: PackageSupport.calendar,
            limits: exactLimits
        )

        do {
            _ = try CookleDataArchivePackageCodec.validatedArchive(
                from: package,
                calendar: PackageSupport.calendar,
                limits: LimitSupport.makeLimits(
                    maximumManifestByteCount: package.manifestData.count - 1
                )
            )
            Issue.record("Expected manifest byte validation to fail.")
        } catch let ArchiveError.resourceByteCountExceeded(
            category,
            actualByteCount,
            maximumByteCount
        ) {
            #expect(category == .manifestData)
            #expect(actualByteCount == package.manifestData.count)
            #expect(maximumByteCount == package.manifestData.count - 1)
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_accepts_photo_limit_and_rejects_one_byte_less() throws {
        let package = try PackageSupport.package()

        _ = try CookleDataArchivePackageCodec.validatedArchive(
            from: package,
            calendar: PackageSupport.calendar,
            limits: LimitSupport.makeLimits(
                maximumPhotoByteCount: PackageSupport.photoData.count
            )
        )

        do {
            _ = try CookleDataArchivePackageCodec.validatedArchive(
                from: package,
                calendar: PackageSupport.calendar,
                limits: LimitSupport.makeLimits(
                    maximumPhotoByteCount: PackageSupport.photoData.count - 1
                )
            )
            Issue.record("Expected photo byte validation to fail.")
        } catch let ArchiveError.resourceByteCountExceeded(
            category,
            actualByteCount,
            maximumByteCount
        ) {
            #expect(category == .photoData)
            #expect(actualByteCount == PackageSupport.photoData.count)
            #expect(maximumByteCount == PackageSupport.photoData.count - 1)
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_accepts_aggregate_limit_and_rejects_one_byte_less() throws {
        let photoPayloads = [
            Data(repeating: 1, count: 3),
            Data(repeating: 2, count: 3)
        ]
        let package = try PackageSupport.package(
            photoPayloads: photoPayloads
        )
        let aggregateByteCount = photoPayloads.reduce(.zero) { result, data in
            result + data.count
        }

        _ = try CookleDataArchivePackageCodec.validatedArchive(
            from: package,
            calendar: PackageSupport.calendar,
            limits: LimitSupport.makeLimits(
                maximumPhotoByteCount: 3,
                maximumAggregatePhotoByteCount: aggregateByteCount
            )
        )

        do {
            _ = try CookleDataArchivePackageCodec.validatedArchive(
                from: package,
                calendar: PackageSupport.calendar,
                limits: LimitSupport.makeLimits(
                    maximumPhotoByteCount: 3,
                    maximumAggregatePhotoByteCount: aggregateByteCount - 1
                )
            )
            Issue.record("Expected aggregate photo byte validation to fail.")
        } catch let ArchiveError.resourceByteCountExceeded(
            category,
            actualByteCount,
            maximumByteCount
        ) {
            #expect(category == .aggregatePhotoData)
            #expect(actualByteCount == aggregateByteCount)
            #expect(maximumByteCount == aggregateByteCount - 1)
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_accepts_package_limit_and_rejects_one_byte_less() throws {
        let package = try PackageSupport.package()
        let packageByteCount = package.manifestData.count
            + package.photoFiles.reduce(.zero) { result, photoFile in
                result + photoFile.data.count
            }

        _ = try CookleDataArchivePackageCodec.validatedArchive(
            from: package,
            calendar: PackageSupport.calendar,
            limits: LimitSupport.makeLimits(
                maximumPackageByteCount: packageByteCount
            )
        )

        do {
            _ = try CookleDataArchivePackageCodec.validatedArchive(
                from: package,
                calendar: PackageSupport.calendar,
                limits: LimitSupport.makeLimits(
                    maximumPackageByteCount: packageByteCount - 1
                )
            )
            Issue.record("Expected package byte validation to fail.")
        } catch let ArchiveError.resourceByteCountExceeded(
            category,
            actualByteCount,
            maximumByteCount
        ) {
            #expect(category == .packageData)
            #expect(actualByteCount == packageByteCount)
            #expect(maximumByteCount == packageByteCount - 1)
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_rejects_manifest_photo_count_above_limit() throws {
        let package = try PackageSupport.package(
            photoPayloads: [
                Data([1]),
                Data([2])
            ]
        )

        do {
            _ = try CookleDataArchivePackageCodec.validatedArchive(
                from: package,
                calendar: PackageSupport.calendar,
                limits: LimitSupport.makeLimits(
                    maximumTopLevelRecordCountPerCategory: 1
                )
            )
            Issue.record("Expected manifest photo count validation to fail.")
        } catch let ArchiveError.resourceCountExceeded(
            category,
            actualCount,
            maximumCount
        ) {
            #expect(category == .photoRecords)
            #expect(actualCount == 2)
            #expect(maximumCount == 1)
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_rejects_actual_photo_file_count_above_limit() throws {
        let package = try PackageSupport.package()
        let invalidPackage: CookleDataArchivePackage = .init(
            manifestData: package.manifestData,
            photoFiles: package.photoFiles + [
                .init(
                    filename: "photo-000002.data",
                    data: Data()
                )
            ]
        )

        do {
            _ = try CookleDataArchivePackageCodec.validatedArchive(
                from: invalidPackage,
                calendar: PackageSupport.calendar,
                limits: LimitSupport.makeLimits(
                    maximumTopLevelRecordCountPerCategory: 1
                )
            )
            Issue.record("Expected photo file count validation to fail.")
        } catch let ArchiveError.resourceCountExceeded(
            category,
            actualCount,
            maximumCount
        ) {
            #expect(category == .photoFiles)
            #expect(actualCount == 2)
            #expect(maximumCount == 1)
        } catch {
            Issue.record(error)
        }
    }
}
