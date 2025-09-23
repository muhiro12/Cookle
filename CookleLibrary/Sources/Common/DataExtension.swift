import UIKit

extension Data {
    public func compressed(maxSize: Int = 500 * 1_024) -> Data {
        var compressed = self
        var compressionQuality = 1.0

        while compressed.count > maxSize && compressionQuality > 0 {
            if let jpeg = UIImage(data: self)?.jpegData(compressionQuality: compressionQuality) {
                compressed = jpeg
            }
            compressionQuality -= 0.1
        }

        return compressed.count < count ? compressed : self
    }
}
