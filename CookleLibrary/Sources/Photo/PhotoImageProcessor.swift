import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Processes stored photo data without depending on an app UI surface.
public enum PhotoImageProcessor {
    private enum Compression {
        static let defaultMaximumKilobytes = 500
        static let bytesPerKilobyte = 1_024
        static let defaultMaximumLongestEdge = 2_048
        static let qualityStepCount = 10
        static let destinationImageCount = 1
    }

    /// Default maximum byte count used when compressing stored photo data.
    nonisolated public static let defaultMaximumByteCount =
        Compression.defaultMaximumKilobytes * Compression.bytesPerKilobyte

    /// Default maximum longest image edge used when normalizing stored photo data.
    nonisolated public static let defaultMaximumLongestEdge =
        Compression.defaultMaximumLongestEdge

    /// Creates a display-ready image whose longest edge does not exceed the supplied pixel size.
    nonisolated public static func downsampledImage(
        from data: Data,
        maximumPixelSize: Int
    ) -> CGImage? {
        guard maximumPixelSize > .zero else {
            return nil
        }

        guard let source = imageSource(from: data) else {
            return nil
        }

        return thumbnailImage(
            from: source,
            maximumLongestEdge: maximumPixelSize
        )
    }

    /// Returns original data within both limits, or a bounded JPEG representation.
    ///
    /// Invalid image data is returned unchanged to preserve the existing caller contract.
    nonisolated public static func compressedData(
        from data: Data,
        maximumByteCount: Int = Self.defaultMaximumByteCount,
        maximumLongestEdge: Int = Self.defaultMaximumLongestEdge
    ) -> Data {
        guard maximumByteCount >= .zero,
              maximumLongestEdge > .zero,
              let source = imageSource(from: data),
              let sourceLongestEdge = sourceLongestEdge(from: source) else {
            return data
        }

        guard data.count > maximumByteCount
                || sourceLongestEdge > maximumLongestEdge else {
            return data
        }

        return compressedJPEGData(
            from: source,
            maximumByteCount: maximumByteCount,
            maximumLongestEdge: maximumLongestEdge
        ) ?? data
    }

    /// Creates bounded JPEG data from valid image data.
    ///
    /// The source is always decoded through ImageIO's thumbnail path. When no quality
    /// reaches `maximumByteCount`, the smallest valid JPEG from the quality sweep is returned.
    nonisolated public static func compressedJPEGData(
        from data: Data,
        maximumByteCount: Int = Self.defaultMaximumByteCount,
        maximumLongestEdge: Int = Self.defaultMaximumLongestEdge
    ) -> Data? {
        guard maximumByteCount >= .zero,
              maximumLongestEdge > .zero,
              let source = imageSource(from: data) else {
            return nil
        }

        return compressedJPEGData(
            from: source,
            maximumByteCount: maximumByteCount,
            maximumLongestEdge: maximumLongestEdge
        )
    }
}

nonisolated private extension PhotoImageProcessor {
    static func imageSource(from data: Data) -> CGImageSource? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        return CGImageSourceCreateWithData(
            data as CFData,
            options as CFDictionary
        )
    }

    static func sourceLongestEdge(from source: CGImageSource) -> Int? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(
            source,
            .zero,
            nil
        ) as? [CFString: Any],
        let width = properties[kCGImagePropertyPixelWidth] as? Int,
        let height = properties[kCGImagePropertyPixelHeight] as? Int,
        width > .zero,
        height > .zero else {
            return nil
        }

        return max(width, height)
    }

    static func thumbnailImage(
        from source: CGImageSource,
        maximumLongestEdge: Int
    ) -> CGImage? {
        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumLongestEdge
        ]
        return CGImageSourceCreateThumbnailAtIndex(
            source,
            .zero,
            thumbnailOptions as CFDictionary
        )
    }

    static func compressedJPEGData(
        from source: CGImageSource,
        maximumByteCount: Int,
        maximumLongestEdge: Int
    ) -> Data? {
        guard let image = thumbnailImage(
            from: source,
            maximumLongestEdge: maximumLongestEdge
        ) else {
            return nil
        }

        var smallestJPEGData = Data?.none
        for qualityStep in stride(
            from: Compression.qualityStepCount,
            through: .zero,
            by: -1
        ) {
            let compressionQuality = Double(qualityStep)
                / Double(Compression.qualityStepCount)
            guard let jpegData = jpegData(
                from: image,
                compressionQuality: compressionQuality
            ) else {
                continue
            }

            if jpegData.count <= maximumByteCount {
                return jpegData
            }
            if jpegData.count < (smallestJPEGData?.count ?? .max) {
                smallestJPEGData = jpegData
            }
        }
        return smallestJPEGData
    }

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
