import CookleLibrary
import CoreGraphics
import Foundation

actor CooklePhotoImageCache {
    nonisolated struct KeyValue: Hashable, Sendable {
        let request: CooklePhotoImageRequest
        let sourceDigest: Data
    }

    nonisolated struct LoadHandle: Sendable {
        let key: KeyValue
        let loadID: UUID
        let waiterID: UUID
        let task: Task<CGImage?, Never>
    }

    nonisolated enum Load: Sendable {
        case cached(CGImage)
        case pending(LoadHandle)
    }

    private enum Limit {
        static let maximumMegabytes = 64
        static let bytesPerMegabyte = 1_048_576
        static let totalCost = maximumMegabytes * bytesPerMegabyte
        static let count = 128
    }

    private struct PendingLoad {
        let id: UUID
        var waiterIDs: Set<UUID>
        let task: Task<CGImage?, Never>
    }

    private final class CacheKey: NSObject {
        let value: KeyValue

        override var hash: Int {
            value.hashValue
        }

        init(value: KeyValue) {
            self.value = value
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? CacheKey else {
                return false
            }
            return value == other.value
        }
    }

    private final class Entry {
        let image: CGImage

        init(image: CGImage) {
            self.image = image
        }
    }

    private let storage = NSCache<CacheKey, Entry>()
    private var pendingLoads = [KeyValue: PendingLoad]()

    init() {
        storage.totalCostLimit = Limit.totalCost
        storage.countLimit = Limit.count
    }

    func load(
        for key: KeyValue,
        data: Data
    ) -> Load {
        let cacheKey = CacheKey(value: key)
        if let entry = storage.object(forKey: cacheKey) {
            return .cached(entry.image)
        }

        let waiterID = UUID()
        if var pendingLoad = pendingLoads[key] {
            pendingLoad.waiterIDs.insert(waiterID)
            pendingLoads[key] = pendingLoad
            return .pending(
                .init(
                    key: key,
                    loadID: pendingLoad.id,
                    waiterID: waiterID,
                    task: pendingLoad.task
                )
            )
        }

        let task = Task.detached(priority: .userInitiated) {
            guard Task.isCancelled == false else {
                return CGImage?.none
            }
            return PhotoImageProcessor.downsampledImage(
                from: data,
                maximumPixelSize: key.request.size.rawValue
            )
        }
        let pendingLoad = PendingLoad(
            id: UUID(),
            waiterIDs: [waiterID],
            task: task
        )
        pendingLoads[key] = pendingLoad
        return .pending(
            .init(
                key: key,
                loadID: pendingLoad.id,
                waiterID: waiterID,
                task: task
            )
        )
    }

    func complete(
        _ handle: LoadHandle,
        image: CGImage?
    ) {
        guard let pendingLoad = pendingLoads[handle.key],
              pendingLoad.id == handle.loadID else {
            return
        }
        pendingLoads[handle.key] = nil

        guard let image else {
            return
        }
        let key = CacheKey(value: handle.key)
        let entry = Entry(image: image)
        let (cost, overflow) = image.bytesPerRow.multipliedReportingOverflow(
            by: image.height
        )
        storage.setObject(
            entry,
            forKey: key,
            cost: overflow ? .zero : cost
        )
    }

    func cancel(_ handle: LoadHandle) {
        guard var pendingLoad = pendingLoads[handle.key],
              pendingLoad.id == handle.loadID else {
            return
        }

        pendingLoad.waiterIDs.remove(handle.waiterID)
        guard pendingLoad.waiterIDs.isEmpty else {
            pendingLoads[handle.key] = pendingLoad
            return
        }

        pendingLoad.task.cancel()
        pendingLoads[handle.key] = nil
    }
}
