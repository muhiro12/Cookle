import CoreGraphics
import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

nonisolated enum CameraImageEncoder {
    struct Source: Sendable {
        let image: CGImage
        let orientation: CGImagePropertyOrientation

        init?(image: UIImage) {
            guard let cgImage = image.cgImage else {
                return nil
            }

            self.image = cgImage
            self.orientation = Self.orientation(
                for: image.imageOrientation
            )
        }

        private static func orientation(
            for imageOrientation: UIImage.Orientation
        ) -> CGImagePropertyOrientation {
            switch imageOrientation {
            case .up:
                .up
            case .upMirrored:
                .upMirrored
            case .down:
                .down
            case .downMirrored:
                .downMirrored
            case .left:
                .left
            case .leftMirrored:
                .leftMirrored
            case .right:
                .right
            case .rightMirrored:
                .rightMirrored
            @unknown default:
                .up
            }
        }
    }

    private enum Encoding {
        static let destinationImageCount = 1
        static let jpegCompressionQuality = 1.0
    }

    static func data(
        from source: Source
    ) async -> Data? {
        let encodingTask = Task.detached(priority: .userInitiated) {
            encodedData(
                from: source
            )
        }
        return await withTaskCancellationHandler {
            await encodingTask.value
        } onCancel: {
            encodingTask.cancel()
        }
    }

    private static func encodedData(
        from source: Source
    ) -> Data? {
        guard Task.isCancelled == false else {
            return nil
        }

        if let data = encodedData(
            from: source,
            contentType: .jpeg,
            properties: [
                kCGImageDestinationLossyCompressionQuality:
                    Encoding.jpegCompressionQuality,
                kCGImagePropertyOrientation: source.orientation.rawValue
            ]
        ) {
            return data
        }

        guard Task.isCancelled == false else {
            return nil
        }
        return encodedData(
            from: source,
            contentType: .png,
            properties: [
                kCGImagePropertyOrientation: source.orientation.rawValue
            ]
        )
    }

    private static func encodedData(
        from source: Source,
        contentType: UTType,
        properties: [CFString: Any]
    ) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            contentType.identifier as CFString,
            Encoding.destinationImageCount,
            nil
        ) else {
            return nil
        }

        CGImageDestinationAddImage(
            destination,
            source.image,
            properties as CFDictionary
        )
        guard CGImageDestinationFinalize(destination),
              Task.isCancelled == false else {
            return nil
        }
        return data as Data
    }
}
