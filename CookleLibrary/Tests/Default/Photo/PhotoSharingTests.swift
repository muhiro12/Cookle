import CookleLibrary
import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@Suite("Photo sharing")
struct PhotoSharingTests {
    @Test("Sharing produces an oriented PNG without source metadata")
    func sharesPixelsWithoutMetadata() throws {
        let original = try PhotoImageProcessorTestFixture.makePNGData(width: 60, height: 30)
        let source = try PhotoImageProcessorTestFixture.imageSource(from: original)
        let fixture = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(
            fixture,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ))
        let metadata: [CFString: Any] = [
            kCGImagePropertyOrientation: CGImagePropertyOrientation.right.rawValue,
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude: 35.0,
                kCGImagePropertyGPSLatitudeRef: "N",
                kCGImagePropertyGPSLongitude: 139.0,
                kCGImagePropertyGPSLongitudeRef: "E"
            ],
            kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFArtist: "Synthetic owner"],
            kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: "2026:01:02 03:04:05"]
        ]
        CGImageDestinationAddImageFromSource(destination, source, .zero, metadata as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        let input = fixture as Data
        let inputProperties = try properties(of: input)
        #expect(inputProperties[kCGImagePropertyGPSDictionary] != nil)
        #expect(inputProperties[kCGImagePropertyTIFFDictionary] != nil)
        let inputExif = try #require(inputProperties[kCGImagePropertyExifDictionary] as? [CFString: Any])
        #expect(inputExif[kCGImagePropertyExifDateTimeOriginal] != nil)

        let output = try #require(PhotoImageProcessor.sharePNGData(from: input))
        let outputSource = try PhotoImageProcessorTestFixture.imageSource(from: output)
        let dimensions = try PhotoImageProcessorTestFixture.imageDimensions(from: outputSource)
        let outputProperties = try properties(of: output)

        #expect(CGImageSourceGetType(outputSource) == UTType.png.identifier as CFString)
        #expect(dimensions.width == 30)
        #expect(dimensions.height == 60)
        #expect(outputProperties[kCGImagePropertyGPSDictionary] == nil)
        #expect(outputProperties[kCGImagePropertyTIFFDictionary] == nil)
        let outputExif = outputProperties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        #expect(outputExif?[kCGImagePropertyExifDateTimeOriginal] == nil)
    }

    @Test("Large shared photos remain bounded")
    func boundsImageDimensions() throws {
        let original = try PhotoImageProcessorTestFixture.makePNGData(
            width: PhotoImageProcessor.defaultMaximumLongestEdge + 1,
            height: 2
        )
        let output = try #require(PhotoImageProcessor.sharePNGData(from: original))
        let source = try PhotoImageProcessorTestFixture.imageSource(from: output)
        let dimensions = try PhotoImageProcessorTestFixture.imageDimensions(from: source)
        #expect(max(dimensions.width, dimensions.height) <= PhotoImageProcessor.defaultMaximumLongestEdge)
    }

    @Test("Sharing preserves transparent pixels")
    func preservesTransparency() throws {
        let context = try #require(CGContext(
            data: nil,
            width: 2,
            height: 2,
            bitsPerComponent: 8,
            bytesPerRow: 8,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.clear(.init(x: 0, y: 0, width: 2, height: 2))
        let image = try #require(context.makeImage())
        let input = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(
            input,
            UTType.png.identifier as CFString,
            1,
            nil
        ))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))

        let output = try #require(PhotoImageProcessor.sharePNGData(from: input as Data))
        let source = try PhotoImageProcessorTestFixture.imageSource(from: output)
        let decoded = try #require(CGImageSourceCreateImageAtIndex(source, .zero, nil))
        context.setBlendMode(.copy)
        context.draw(decoded, in: .init(x: 0, y: 0, width: 2, height: 2))
        let pixels = try #require(context.data).assumingMemoryBound(to: UInt8.self)
        #expect(pixels[3] == .zero)
        #expect(pixels[15] == .zero)
    }

    @Test("Unreadable data is not forwarded as a shared image")
    func rejectsUnreadableData() {
        #expect(PhotoImageProcessor.sharePNGData(from: Data()) == nil)
    }

    private func properties(of data: Data) throws -> [CFString: Any] {
        let source = try PhotoImageProcessorTestFixture.imageSource(from: data)
        return try #require(CGImageSourceCopyPropertiesAtIndex(source, .zero, nil) as? [CFString: Any])
    }
}
