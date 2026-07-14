import CookleLibrary
import CoreGraphics
import CryptoKit
import Foundation

nonisolated final class CooklePhotoImagePipeline: Sendable {
    static let shared = CooklePhotoImagePipeline()

    private let cache = CooklePhotoImageCache()

    func image(
        for request: CooklePhotoImageRequest,
        data: Data
    ) async -> CGImage? {
        guard Task.isCancelled == false else {
            return nil
        }

        guard let sourceDigest = await sourceDigest(for: data) else {
            return nil
        }

        let key = CooklePhotoImageCache.KeyValue(
            request: request,
            sourceDigest: sourceDigest
        )
        switch await cache.load(for: key, data: data) {
        case let .cached(image):
            return image
        case let .pending(handle):
            let image = await withTaskCancellationHandler {
                let image = await handle.task.value
                await cache.complete(
                    handle,
                    image: image
                )
                return image
            } onCancel: {
                Task {
                    await cache.cancel(handle)
                }
            }

            guard Task.isCancelled == false else {
                return nil
            }
            return image
        }
    }

    private func sourceDigest(for data: Data) async -> Data? {
        let digestTask = Task.detached(priority: .userInitiated) {
            guard Task.isCancelled == false else {
                return Data?.none
            }
            return Data(SHA256.hash(data: data))
        }
        let digest = await withTaskCancellationHandler {
            await digestTask.value
        } onCancel: {
            digestTask.cancel()
        }

        guard Task.isCancelled == false else {
            return nil
        }
        return digest
    }
}
