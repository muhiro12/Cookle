import Foundation
import ImageIO
import UniformTypeIdentifiers

public extension PhotoImageProcessor {
    /// Creates a still PNG for sharing, applying orientation and preserving transparency.
    ///
    /// Re-encoding pixels omits source metadata such as location and camera details.
    /// The longest edge is bounded by the stored-photo limit. Invalid data is never
    /// forwarded as an image; callers must handle a nil result.
    nonisolated static func sharePNGData(from data: Data) -> Data? {
        guard let image = downsampledImage(
            from: data,
            maximumPixelSize: defaultMaximumLongestEdge
        ) else {
            return nil
        }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return output as Data
    }
}
