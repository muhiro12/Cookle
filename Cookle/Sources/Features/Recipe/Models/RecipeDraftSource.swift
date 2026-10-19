import SwiftUI

enum RecipeDraftSource: CaseIterable, Identifiable {
    case generation
    case text
    case photo
    case website

    var id: Self {
        self
    }

    var title: LocalizedStringKey {
        switch self {
        case .generation:
            "Create with AI"
        case .text:
            "Import from Text"
        case .photo:
            "Read Recipe from Photo"
        case .website:
            "Import from Website"
        }
    }

    var systemImage: String {
        switch self {
        case .generation:
            "sparkles"
        case .text:
            "text.alignleft"
        case .photo:
            "text.viewfinder"
        case .website:
            "link"
        }
    }
}
