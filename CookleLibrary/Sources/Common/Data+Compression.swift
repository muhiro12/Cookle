import UIKit

@usableFromInline
enum DataCompressionConstants {
    @usableFromInline static let defaultMaxSizeKilobytes = 500
    @usableFromInline static let bytesPerKilobyte = 1_024
    @usableFromInline static let defaultMaxSize =
        defaultMaxSizeKilobytes * bytesPerKilobyte
    static let initialQuality = 1.0
    static let minimumQuality = 0.0
    static let qualityStep = 0.1
}

public extension Data {
    /// Returns JPEG-compressed data capped near the supplied byte size.
    func compressed(
        maxSize: Int = DataCompressionConstants.defaultMaxSize
    ) -> Data {
        var compressed = self
        var compressionQuality = DataCompressionConstants.initialQuality

        while compressed.count > maxSize,
              compressionQuality > DataCompressionConstants.minimumQuality {
            if let jpeg = UIImage(data: self)?.jpegData(compressionQuality: compressionQuality) {
                compressed = jpeg
            }
            compressionQuality -= DataCompressionConstants.qualityStep
        }

        return compressed.count < count ? compressed : self
    }
}
