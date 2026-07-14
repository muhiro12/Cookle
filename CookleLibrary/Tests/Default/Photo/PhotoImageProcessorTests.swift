import CookleLibrary
import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@Suite("PhotoImageProcessor")
struct PhotoImageProcessorTests {
    private enum Fixture {
        static let bytesPerPixel = 4
        static let bitsPerComponent = 8
        static let bitsPerByte = 8
        static let firstRandomShift = 13
        static let secondRandomShift = 17
        static let thirdRandomShift = 5
        static let greenByteOffset = 1
        static let blueByteOffset = 2
        static let alphaByteOffset = 3
        static let greenBitShift = 8
        static let blueBitShift = 16
        static let destinationImageCount = 1
        static let fullCompressionQuality = 1.0
        static let initialRandomState: UInt32 = 0x1234_5678
    }

    private enum FixtureError: Error {
        case imageCreationFailed
        case destinationCreationFailed
        case destinationFinalizationFailed
    }

    @Test("Downsamples an image to the requested longest edge")
    func downsampledImage_limitsLongestEdge() throws {
        let data = try makeJPEGData(
            width: 120,
            height: 60
        )

        let image = try #require(
            PhotoImageProcessor.downsampledImage(
                from: data,
                maximumPixelSize: 30
            )
        )

        #expect(image.width == 30)
        #expect(image.height == 15)
    }

    @Test("Applies source orientation while downsampling")
    func downsampledImage_appliesOrientation() throws {
        let data = try makeJPEGData(
            width: 120,
            height: 60,
            orientation: .right
        )

        let image = try #require(
            PhotoImageProcessor.downsampledImage(
                from: data,
                maximumPixelSize: 30
            )
        )

        #expect(image.width == 15)
        #expect(image.height == 30)
    }

    @Test("Rejects invalid image data")
    func downsampledImage_rejectsInvalidData() {
        let data = Data("not-an-image".utf8)

        #expect(
            PhotoImageProcessor.downsampledImage(
                from: data,
                maximumPixelSize: 30
            ) == nil
        )
    }

    @Test("Rejects a nonpositive maximum pixel size")
    func downsampledImage_rejectsNonpositivePixelSize() throws {
        let data = try makeJPEGData(
            width: 32,
            height: 32
        )

        #expect(
            PhotoImageProcessor.downsampledImage(
                from: data,
                maximumPixelSize: .zero
            ) == nil
        )
    }

    @Test("Returns unchanged data within the byte limit")
    func compressedData_preservesDataWithinLimit() throws {
        let data = try makeJPEGData(
            width: 32,
            height: 32
        )

        let compressedData = PhotoImageProcessor.compressedData(
            from: data,
            maximumByteCount: data.count
        )

        #expect(compressedData == data)
    }

    @Test("Returns unchanged data when image decoding fails")
    func compressedData_preservesInvalidData() {
        let data = Data(repeating: 0xAB, count: 1_024)

        let compressedData = PhotoImageProcessor.compressedData(
            from: data,
            maximumByteCount: 1
        )

        #expect(compressedData == data)
    }

    @Test("Returns a smaller JPEG when compression is effective")
    func compressedData_reducesImageData() throws {
        let data = try makeJPEGData(
            width: 256,
            height: 256
        )

        let compressedData = PhotoImageProcessor.compressedData(
            from: data,
            maximumByteCount: data.count / 2
        )

        #expect(compressedData.count < data.count)
        let source = try #require(
            CGImageSourceCreateWithData(
                compressedData as CFData,
                nil
            )
        )
        #expect(
            CGImageSourceGetType(source) == UTType.jpeg.identifier as CFString
        )
    }

    private func makeJPEGData(
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

    private func makeImage(
        width: Int,
        height: Int
    ) throws -> CGImage {
        let bytesPerRow = width * Fixture.bytesPerPixel
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
            bitsPerComponent: Fixture.bitsPerComponent,
            bitsPerPixel: Fixture.bytesPerPixel * Fixture.bitsPerByte,
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

    private func makePixels(
        width: Int,
        height: Int
    ) -> [UInt8] {
        let bytesPerRow = width * Fixture.bytesPerPixel
        var pixels = [UInt8](
            repeating: .zero,
            count: height * bytesPerRow
        )
        var randomState = Fixture.initialRandomState

        for pixelIndex in .zero..<(width * height) {
            randomState ^= randomState << Fixture.firstRandomShift
            randomState ^= randomState >> Fixture.secondRandomShift
            randomState ^= randomState << Fixture.thirdRandomShift

            let byteIndex = pixelIndex * Fixture.bytesPerPixel
            pixels[byteIndex] = UInt8(truncatingIfNeeded: randomState)
            pixels[byteIndex + Fixture.greenByteOffset] = UInt8(
                truncatingIfNeeded: randomState >> Fixture.greenBitShift
            )
            pixels[byteIndex + Fixture.blueByteOffset] = UInt8(
                truncatingIfNeeded: randomState >> Fixture.blueBitShift
            )
            pixels[byteIndex + Fixture.alphaByteOffset] = .max
        }
        return pixels
    }

    private func encodeJPEG(
        _ image: CGImage,
        orientation: CGImagePropertyOrientation?
    ) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            Fixture.destinationImageCount,
            nil
        ) else {
            throw FixtureError.destinationCreationFailed
        }

        var properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: Fixture.fullCompressionQuality
        ]
        if let orientation {
            properties[kCGImagePropertyOrientation] = orientation.rawValue
        }
        CGImageDestinationAddImage(
            destination,
            image,
            properties as CFDictionary
        )
        guard CGImageDestinationFinalize(destination) else {
            throw FixtureError.destinationFinalizationFailed
        }
        return data as Data
    }
}
