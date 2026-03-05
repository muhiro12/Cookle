import ImageIO
import UIKit
import WidgetKit

enum RecipeWidgetImageLoader {
    private enum Layout {
        static let smallWidgetMaxPixelSize = 340
        static let mediumWidgetMaxPixelSize = 720
    }

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
            return Layout.smallWidgetMaxPixelSize
        case .systemMedium:
            return Layout.mediumWidgetMaxPixelSize
        default:
            return Layout.mediumWidgetMaxPixelSize
        }
    }
}
