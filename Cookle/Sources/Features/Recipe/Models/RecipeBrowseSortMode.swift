import SwiftUI

extension RecipeBrowseSortMode {
    var title: LocalizedStringKey {
        switch self {
        case .alphabetical:
            "Alphabetical"
        case .recentlyCreated:
            "Recently Created"
        case .madeCount:
            "Made Count"
        }
    }
}
