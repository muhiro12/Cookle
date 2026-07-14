import Foundation
import SwiftData

extension CookleDataArchiveService {
    /// Builds a version 2 package with photo payloads stored outside the manifest.
    static func archivePackage(
        from context: ModelContext,
        calendar: Calendar = .current,
        limits: CookleDataArchiveResourceLimits = .standard
    ) async throws -> CookleDataArchivePackage {
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
            try await packageTask.value
        } onCancel: {
            packageTask.cancel()
        }
    }

    /// Validates a version 2 package and hydrates the canonical restore archive.
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
