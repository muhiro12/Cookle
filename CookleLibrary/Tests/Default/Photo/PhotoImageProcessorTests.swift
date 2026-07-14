import CookleLibrary
import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@Suite("PhotoImageProcessor")
struct PhotoImageProcessorTests {
    private enum Fixture {
        static let qualityStepCount = PhotoImageProcessorTestFixture.qualityStepCount
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

    @Test("Returns unchanged valid data within byte and dimension limits")
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

    @Test("Normalizes a high-dimension image below the byte limit")
    func compressedData_normalizesHighDimensionWithinByteLimit() throws {
        let data = try makeJPEGData(
            width: PhotoImageProcessor.defaultMaximumLongestEdge + 1,
            height: 1
        )
        #expect(data.count < PhotoImageProcessor.defaultMaximumByteCount)

        let compressedData = PhotoImageProcessor.compressedData(
            from: data
        )
        let source = try imageSource(from: compressedData)
        let dimensions = try imageDimensions(from: source)

        #expect(compressedData != data)
        #expect(
            max(dimensions.width, dimensions.height)
                <= PhotoImageProcessor.defaultMaximumLongestEdge
        )
        #expect(
            CGImageSourceGetType(source) == UTType.jpeg.identifier as CFString
        )
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

    @Test("Creates bounded JPEG data from a PNG source")
    func compressedJPEGData_convertsPNGToJPEG() throws {
        let data = try makePNGData(
            width: 64,
            height: 32
        )

        let jpegData = try #require(
            PhotoImageProcessor.compressedJPEGData(
                from: data,
                maximumByteCount: .max
            )
        )
        let source = try imageSource(from: jpegData)
        let dimensions = try imageDimensions(from: source)

        #expect(
            CGImageSourceGetType(source) == UTType.jpeg.identifier as CFString
        )
        #expect(dimensions.width == 64)
        #expect(dimensions.height == 32)
    }

    @Test("Applies orientation while producing bounded JPEG data")
    func compressedJPEGData_appliesOrientation() throws {
        let data = try makeJPEGData(
            width: 120,
            height: 60,
            orientation: .right
        )

        let jpegData = try #require(
            PhotoImageProcessor.compressedJPEGData(
                from: data,
                maximumByteCount: .max,
                maximumLongestEdge: 30
            )
        )
        let source = try imageSource(from: jpegData)
        let dimensions = try imageDimensions(from: source)

        #expect(
            CGImageSourceGetType(source) == UTType.jpeg.identifier as CFString
        )
        #expect(dimensions.width == 15)
        #expect(dimensions.height == 30)
    }

    @Test("Rejects invalid data when producing JPEG data")
    func compressedJPEGData_rejectsInvalidData() {
        let data = Data("not-an-image".utf8)

        #expect(
            PhotoImageProcessor.compressedJPEGData(
                from: data
            ) == nil
        )
    }

    @Test("Returns the smallest JPEG when the byte target is unattainable")
    func compressedJPEGData_returnsSmallestFallback() throws {
        let maximumLongestEdge = 64
        let data = try makeJPEGData(
            width: maximumLongestEdge,
            height: maximumLongestEdge
        )
        let image = try #require(
            PhotoImageProcessor.downsampledImage(
                from: data,
                maximumPixelSize: maximumLongestEdge
            )
        )
        let expectedByteCounts = try stride(
            from: Fixture.qualityStepCount,
            through: .zero,
            by: -1
        ).map { qualityStep in
            try encodeJPEG(
                image,
                compressionQuality: Double(qualityStep)
                    / Double(Fixture.qualityStepCount)
            ).count
        }
        let expectedMinimumByteCount = try #require(expectedByteCounts.min())

        let jpegData = try #require(
            PhotoImageProcessor.compressedJPEGData(
                from: data,
                maximumByteCount: 1,
                maximumLongestEdge: maximumLongestEdge
            )
        )

        #expect(jpegData.count == expectedMinimumByteCount)
        #expect(jpegData.count > 1)
        #expect(
            CGImageSourceGetType(try imageSource(from: jpegData))
                == UTType.jpeg.identifier as CFString
        )
    }

    private func makeJPEGData(
        width: Int,
        height: Int,
        orientation: CGImagePropertyOrientation? = nil
    ) throws -> Data {
        try PhotoImageProcessorTestFixture.makeJPEGData(
            width: width,
            height: height,
            orientation: orientation
        )
    }

    private func makePNGData(
        width: Int,
        height: Int
    ) throws -> Data {
        try PhotoImageProcessorTestFixture.makePNGData(
            width: width,
            height: height
        )
    }

    private func encodeJPEG(
        _ image: CGImage,
        compressionQuality: Double,
        orientation: CGImagePropertyOrientation? = nil
    ) throws -> Data {
        try PhotoImageProcessorTestFixture.encodeJPEG(
            image,
            compressionQuality: compressionQuality,
            orientation: orientation
        )
    }

    private func imageSource(from data: Data) throws -> CGImageSource {
        try PhotoImageProcessorTestFixture.imageSource(from: data)
    }

    private func imageDimensions(
        from source: CGImageSource
    ) throws -> (width: Int, height: Int) {
        try PhotoImageProcessorTestFixture.imageDimensions(from: source)
    }
}
