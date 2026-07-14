import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum PhotoImageProcessorTestFixture {
    enum FixtureError: Error {
        case destinationCreationFailed
        case destinationFinalizationFailed
        case imageCreationFailed
        case imagePropertiesUnavailable
        case imageSourceCreationFailed
    }

    private static let bytesPerPixel = 4
    private static let bitsPerComponent = 8
    private static let bitsPerByte = 8
    private static let firstRandomShift = 13
    private static let secondRandomShift = 17
    private static let thirdRandomShift = 5
    private static let greenByteOffset = 1
    private static let blueByteOffset = 2
    private static let alphaByteOffset = 3
    private static let greenBitShift = 8
    private static let blueBitShift = 16
    private static let destinationImageCount = 1
    private static let fullCompressionQuality = 1.0
    private static let initialRandomState: UInt32 = 0x1234_5678

    static let qualityStepCount = 10

    static func makeJPEGData(
        width: Int,
        height: Int,
        orientation: CGImagePropertyOrientation? = nil
    ) throws -> Data {
        let image = try makeImage(
            width: width,
            height: height
        )
        return try encodeJPEG(
            image,
            orientation: orientation
        )
    }

    static func makePNGData(
        width: Int,
        height: Int
    ) throws -> Data {
        let image = try makeImage(
            width: width,
            height: height
        )
        return try encodeImage(
            image,
            type: .png
        )
    }

    static func encodeJPEG(
        _ image: CGImage,
        compressionQuality: Double = fullCompressionQuality,
        orientation: CGImagePropertyOrientation? = nil
    ) throws -> Data {
        try encodeImage(
            image,
            type: .jpeg,
            compressionQuality: compressionQuality,
            orientation: orientation
        )
    }

    static func imageSource(from data: Data) throws -> CGImageSource {
        guard let source = CGImageSourceCreateWithData(
            data as CFData,
            nil
        ) else {
            throw FixtureError.imageSourceCreationFailed
        }
        return source
    }

    static func imageDimensions(
        from source: CGImageSource
    ) throws -> (width: Int, height: Int) {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(
            source,
            .zero,
            nil
        ) as? [CFString: Any],
        let width = properties[kCGImagePropertyPixelWidth] as? Int,
        let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            throw FixtureError.imagePropertiesUnavailable
        }
        return (width, height)
    }

    private static func makeImage(
        width: Int,
        height: Int
    ) throws -> CGImage {
        let bytesPerRow = width * bytesPerPixel
        let pixels = makePixels(
            width: width,
            height: height
        )
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(
            .init(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        )
        guard let provider = CGDataProvider(
            data: Data(pixels) as CFData
        ),
        let image = CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bytesPerPixel * bitsPerByte,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else {
            throw FixtureError.imageCreationFailed
        }
        return image
    }

    private static func makePixels(
        width: Int,
        height: Int
    ) -> [UInt8] {
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](
            repeating: .zero,
            count: height * bytesPerRow
        )
        var randomState = initialRandomState

        for pixelIndex in .zero..<(width * height) {
            randomState ^= randomState << firstRandomShift
            randomState ^= randomState >> secondRandomShift
            randomState ^= randomState << thirdRandomShift

            let byteIndex = pixelIndex * bytesPerPixel
            pixels[byteIndex] = UInt8(truncatingIfNeeded: randomState)
            pixels[byteIndex + greenByteOffset] = UInt8(
                truncatingIfNeeded: randomState >> greenBitShift
            )
            pixels[byteIndex + blueByteOffset] = UInt8(
                truncatingIfNeeded: randomState >> blueBitShift
            )
            pixels[byteIndex + alphaByteOffset] = .max
        }
        return pixels
    }

    private static func encodeImage(
        _ image: CGImage,
        type: UTType,
        compressionQuality: Double? = nil,
        orientation: CGImagePropertyOrientation? = nil
    ) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            type.identifier as CFString,
            destinationImageCount,
            nil
        ) else {
            throw FixtureError.destinationCreationFailed
        }

        var properties = [CFString: Any]()
        if let compressionQuality {
            properties[kCGImageDestinationLossyCompressionQuality] = compressionQuality
        }
        if let orientation {
            properties[kCGImagePropertyOrientation] = orientation.rawValue
        }
        let propertiesDictionary: CFDictionary? = properties.isEmpty
            ? nil
            : properties as CFDictionary
        CGImageDestinationAddImage(
            destination,
            image,
            propertiesDictionary
        )
        guard CGImageDestinationFinalize(destination) else {
            throw FixtureError.destinationFinalizationFailed
        }
        return data as Data
    }
}
