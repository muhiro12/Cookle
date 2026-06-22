import Foundation
import SwiftData
import SwiftUI

extension CooklePreviewStore {
    enum RemoteImageConstants {
        static let firstOrder = 1
        static let successStatusCodes = 200...299
        static let adjustmentRange = 61
        static let maximumAdjustment = 30
        static let componentScale = CGFloat(UInt8.max)
        static let maximumColorComponent = CGFloat(1)
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
        let tintColor = adjustedTintColor(seed: systemImageName.hashValue)
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

    private func adjustedTintColor(seed: Int) -> UIColor {
        let baseColor = UIColor.tintColor.resolvedColor(with: .current)
        var red = CGFloat.zero
        var green = CGFloat.zero
        var blue = CGFloat.zero
        var alpha = CGFloat.zero
        guard baseColor.getRed(
            &red,
            green: &green,
            blue: &blue,
            alpha: &alpha
        ) else {
            return baseColor
        }

        let redAdjustment = adjustment(for: seed)
        let greenAdjustment = adjustment(
            for: seed / RemoteImageConstants.adjustmentRange
        )
        let blueAdjustment = adjustment(
            for: seed / (
                RemoteImageConstants.adjustmentRange
                    * RemoteImageConstants.adjustmentRange
            )
        )
        return .init(
            red: adjustedComponent(red, by: redAdjustment),
            green: adjustedComponent(green, by: greenAdjustment),
            blue: adjustedComponent(blue, by: blueAdjustment),
            alpha: alpha
        )
    }

    private func adjustedComponent(
        _ component: CGFloat,
        by adjustment: CGFloat
    ) -> CGFloat {
        min(
            max(
                component + adjustment / RemoteImageConstants.componentScale,
                .zero
            ),
            RemoteImageConstants.maximumColorComponent
        )
    }

    private func adjustment(for seed: Int) -> CGFloat {
        CGFloat(
            seed % RemoteImageConstants.adjustmentRange
                - RemoteImageConstants.maximumAdjustment
        )
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
