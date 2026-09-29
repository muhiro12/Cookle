import Foundation
import SwiftData

extension CookleDataArchiveService {
    /// Builds an export package with photo payloads stored outside the manifest.
    static func archivePackage(
        from context: ModelContext,
        calendar: Calendar = .current,
        limits: CookleDataArchiveResourceLimits = .standard
    ) async throws -> CookleDataArchivePackage {
        try Task.checkCancellation()
        let archive = try makeArchive(
            context: context
        )
        let packageTask = Task.detached(priority: .userInitiated) {
            try CookleDataArchivePackageCodec.package(
                from: archive,
                calendar: calendar,
                limits: limits
            )
        }
        return try await withTaskCancellationHandler {
            let package = try await packageTask.value
            try Task.checkCancellation()
            return package
        } onCancel: {
            packageTask.cancel()
        }
    }

    /// Validates an export package and hydrates the canonical archive.
    nonisolated static func validatedArchive(
        from package: CookleDataArchivePackage,
        calendar: Calendar = .current,
        limits: CookleDataArchiveResourceLimits = .standard
    ) throws -> CookleDataArchive {
        try CookleDataArchivePackageCodec.validatedArchive(
            from: package,
            calendar: calendar,
            limits: limits
        )
    }
}
