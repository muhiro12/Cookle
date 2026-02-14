import ImageIO
import UIKit
import WidgetKit

enum RecipeWidgetImageLoader {
    static func makeImage(from imageData: Data, family widgetFamily: WidgetFamily) -> UIImage? {
        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let imageSource = CGImageSourceCreateWithData(
            imageData as CFData,
            sourceOptions as CFDictionary
        ) else {
            return nil
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: false,
            kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize(family: widgetFamily)
        ]
        guard let coreGraphicsImage = CGImageSourceCreateThumbnailAtIndex(
            imageSource,
            .zero,
            thumbnailOptions as CFDictionary
        ) else {
            return UIImage(data: imageData)
        }
        return UIImage(cgImage: coreGraphicsImage)
    }

    private static func maximumPixelSize(family widgetFamily: WidgetFamily) -> Int {
        switch widgetFamily {
        case .systemSmall:
            return 340
        case .systemMedium:
            return 720
        default:
            return 720
        }
    }
}
