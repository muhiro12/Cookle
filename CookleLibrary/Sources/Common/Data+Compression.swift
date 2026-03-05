import UIKit

public extension Data {
    private enum CompressionConstants {
        static let initialQuality = 1.0
        static let minimumQuality = 0.0
        static let qualityStep = 0.1
    }

    /// Returns JPEG-compressed data capped near the supplied byte size.
    func compressed(maxSize: Int = (Int("500") ?? .zero) * (Int("1024") ?? .zero)) -> Data {
        var compressed = self
        var compressionQuality = CompressionConstants.initialQuality

        while compressed.count > maxSize,
              compressionQuality > CompressionConstants.minimumQuality {
            if let jpeg = UIImage(data: self)?.jpegData(compressionQuality: compressionQuality) {
                compressed = jpeg
            }
            compressionQuality -= CompressionConstants.qualityStep
        }

        return compressed.count < count ? compressed : self
    }
}
