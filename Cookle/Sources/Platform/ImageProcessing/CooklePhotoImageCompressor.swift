import CookleLibrary
import Foundation

nonisolated enum CooklePhotoImageCompressor {
    static func compressedData(
        from data: Data
    ) async throws -> Data {
        let compressionTask = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            let compressedData = PhotoImageProcessor.compressedData(
                from: data
            )
            try Task.checkCancellation()
            return compressedData
        }
        return try await withTaskCancellationHandler {
            try await compressionTask.value
        } onCancel: {
            compressionTask.cancel()
        }
    }
}
