import Foundation
import ImageIO
import UniformTypeIdentifiers

@usableFromInline
enum DataCompressionConstants {
    @usableFromInline nonisolated static let defaultMaxSizeKilobytes = 500
    @usableFromInline nonisolated static let bytesPerKilobyte = 1_024
    @usableFromInline nonisolated static let defaultMaxSize =
        defaultMaxSizeKilobytes * bytesPerKilobyte
    nonisolated static let initialQuality = 1.0
    nonisolated static let minimumQuality = 0.0
    nonisolated static let qualityStep = 0.1
    nonisolated static let destinationImageCount = 1
}

public extension Data {
    /// Returns JPEG-compressed data capped near the supplied byte size.
    nonisolated func compressed(
        maxSize: Int = DataCompressionConstants.defaultMaxSize
    ) -> Data {
        guard count > maxSize,
              let source = CGImageSourceCreateWithData(self as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, .zero, nil) else {
            return self
        }

        var compressed = self
        var compressionQuality = DataCompressionConstants.initialQuality

        while compressed.count > maxSize,
              compressionQuality > DataCompressionConstants.minimumQuality {
            if let jpeg = compressedJPEGData(
                from: image,
                quality: compressionQuality
            ) {
                compressed = jpeg
            }
            compressionQuality -= DataCompressionConstants.qualityStep
        }

        return compressed.count < count ? compressed : self
    }
}

nonisolated private func compressedJPEGData(
    from image: CGImage,
    quality: Double
) -> Data? {
    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
        data,
        UTType.jpeg.identifier as CFString,
        DataCompressionConstants.destinationImageCount,
        nil
    ) else {
        return nil
    }

    let options = [
        kCGImageDestinationLossyCompressionQuality: quality
    ] as CFDictionary
    CGImageDestinationAddImage(destination, image, options)
    guard CGImageDestinationFinalize(destination) else {
        return nil
    }
    return data as Data
}
