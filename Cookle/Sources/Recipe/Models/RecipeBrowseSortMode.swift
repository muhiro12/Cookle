import SwiftUI

enum RecipeBrowseSortMode: String, CaseIterable, Identifiable {
    case alphabetical
    case recentlyCreated
    case madeCount

    var id: Self {
        self
    }

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
