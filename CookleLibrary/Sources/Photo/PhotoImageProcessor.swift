import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Processes stored photo data without depending on an app UI surface.
public enum PhotoImageProcessor {
    private enum Compression {
        static let defaultMaximumKilobytes = 500
        static let bytesPerKilobyte = 1_024
        static let initialQuality = 1.0
        static let minimumQuality = 0.0
        static let qualityStep = 0.1
        static let destinationImageCount = 1
    }

    /// Default maximum byte count used when compressing stored photo data.
    nonisolated public static let defaultMaximumByteCount =
        Compression.defaultMaximumKilobytes * Compression.bytesPerKilobyte

    /// Creates a display-ready image whose longest edge does not exceed the supplied pixel size.
    nonisolated public static func downsampledImage(
        from data: Data,
        maximumPixelSize: Int
    ) -> CGImage? {
        guard maximumPixelSize > .zero else {
            return nil
        }

        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithData(
            data as CFData,
            sourceOptions as CFDictionary
        ) else {
            return nil
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize
        ]
        return CGImageSourceCreateThumbnailAtIndex(
            source,
            .zero,
            thumbnailOptions as CFDictionary
        )
    }

    /// Returns JPEG-compressed data when compression reduces the input size, or the original data.
    nonisolated public static func compressedData(
        from data: Data,
        maximumByteCount: Int = Self.defaultMaximumByteCount
    ) -> Data {
        guard data.count > maximumByteCount,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, .zero, nil) else {
            return data
        }

        var compressedData = data
        var compressionQuality = Compression.initialQuality

        while compressedData.count > maximumByteCount,
              compressionQuality > Compression.minimumQuality {
            if let jpegData = jpegData(
                from: image,
                compressionQuality: compressionQuality
            ) {
                compressedData = jpegData
            }
            compressionQuality -= Compression.qualityStep
        }

        return compressedData.count < data.count ? compressedData : data
    }
}

nonisolated private extension PhotoImageProcessor {
    static func jpegData(
        from image: CGImage,
        compressionQuality: Double
    ) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            Compression.destinationImageCount,
            nil
        ) else {
            return nil
        }

        let options = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ] as CFDictionary
        CGImageDestinationAddImage(destination, image, options)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return data as Data
    }
}
