import Foundation
import SwiftData
import SwiftUI

extension CooklePreviewStore {
    enum RemoteImageConstants {
        static let firstOrder = 1
        static let successStatusCodes = 200...299
    }

    func createPhotoObject(_ context: ModelContext, systemName: String, order: Int) -> PhotoObject {
        let photoData = photoDataFromSystemImage(named: systemName)
        return .create(
            context: context,
            photoData: .init(
                data: photoData,
                source: order == RemoteImageConstants.firstOrder ? .photosPicker : .imagePlayground
            ),
            order: order
        )
    }

    func createPhotoObject(
        _ context: ModelContext,
        asset: SamplePhotoAsset,
        order: Int,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) -> PhotoObject {
        let photoData = remotePhotoDataMap[asset]
            ?? photoDataFromSystemImage(named: asset.fallbackSystemImageName)
        return .create(
            context: context,
            photoData: .init(
                data: photoData,
                source: order == RemoteImageConstants.firstOrder ? .photosPicker : .imagePlayground
            ),
            order: order
        )
    }

    func photoDataFromSystemImage(named systemImageName: String) -> Data {
        let tintColor: UIColor = .init(
            .init(uiColor: .tintColor).adjusted(by: systemImageName.hashValue)
        )
        if let imageData = UIImage(systemName: systemImageName)?
            .withTintColor(tintColor)
            .jpegData(compressionQuality: 1) {
            return imageData
        }
        if let fallbackImageData = UIImage(systemName: "photo")?
            .withTintColor(tintColor)
            .jpegData(compressionQuality: 1) {
            return fallbackImageData
        }
        return .init()
    }

    func fetchRemotePhotoDataMap() async -> [SamplePhotoAsset: Data] {
        let uncachedAssets = SamplePhotoAsset.allCases.filter { samplePhotoAsset in
            remotePhotoDataCache[samplePhotoAsset] == nil
        }
        guard !uncachedAssets.isEmpty else {
            return remotePhotoDataCache
        }

        let remoteImageSession = remoteImageSession
        let fetchedPhotoPairs = await withTaskGroup(
            of: (SamplePhotoAsset, Data?).self,
            returning: [(SamplePhotoAsset, Data)].self
        ) { taskGroup in
            for samplePhotoAsset in uncachedAssets {
                let remoteImageURL = samplePhotoAsset.remoteImageURL
                taskGroup.addTask {
                    let remotePhotoData = await self.fetchRemotePhotoData(
                        remoteImageURL: remoteImageURL,
                        remoteImageSession: remoteImageSession
                    )
                    return (samplePhotoAsset, remotePhotoData)
                }
            }

            var collectedPhotoPairs = [(SamplePhotoAsset, Data)]()
            for await (samplePhotoAsset, remotePhotoData) in taskGroup {
                guard let remotePhotoData else {
                    continue
                }
                collectedPhotoPairs.append((samplePhotoAsset, remotePhotoData))
            }
            return collectedPhotoPairs
        }

        for (samplePhotoAsset, remotePhotoData) in fetchedPhotoPairs {
            remotePhotoDataCache[samplePhotoAsset] = remotePhotoData
        }
        return remotePhotoDataCache
    }

    func fetchRemotePhotoData(
        remoteImageURL: URL?,
        remoteImageSession: URLSession
    ) async -> Data? {
        guard let remoteImageURL else {
            return nil
        }
        do {
            let (remotePhotoData, response) = try await remoteImageSession.data(from: remoteImageURL)
            guard let httpURLResponse = response as? HTTPURLResponse else {
                return nil
            }
            guard RemoteImageConstants.successStatusCodes.contains(httpURLResponse.statusCode) else {
                return nil
            }
            guard !remotePhotoData.isEmpty else {
                return nil
            }
            return remotePhotoData
        } catch {
            return nil
        }
    }
}
