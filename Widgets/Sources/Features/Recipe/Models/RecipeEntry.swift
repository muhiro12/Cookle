import Foundation
import UIKit
import WidgetKit

struct RecipeEntry: TimelineEntry {
    let date: Date
    let titleText: String
    let image: UIImage?
    let deepLinkURL: URL?
}
