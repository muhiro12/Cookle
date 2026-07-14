import CookleLibrary
import UIKit
import WidgetKit

enum RecipeWidgetImageLoader {
    private enum Layout {
        static let smallWidgetMaxPixelSize = 340
        static let mediumWidgetMaxPixelSize = 720
    }

    static func makeImage(from imageData: Data, family widgetFamily: WidgetFamily) -> UIImage? {
        guard let image = PhotoImageProcessor.downsampledImage(
            from: imageData,
            maximumPixelSize: maximumPixelSize(
                family: widgetFamily
            )
        ) else {
            return nil
        }
        return .init(cgImage: image)
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
