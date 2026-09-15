import SwiftUI

enum RecipeImportSource: CaseIterable, Identifiable {
    case text
    case photo
    case website

    var id: Self {
        self
    }

    var title: LocalizedStringKey {
        switch self {
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
        case .text:
            "text.alignleft"
        case .photo:
            "text.viewfinder"
        case .website:
            "link"
        }
    }
}
