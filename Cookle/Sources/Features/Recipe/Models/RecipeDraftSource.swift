import SwiftUI

enum RecipeDraftSource: CaseIterable, Identifiable {
    case text
    case photo
    case website
    case generation

    var id: Self {
        self
    }

    var isAvailable: Bool {
        switch self {
        case .generation:
            if #available(iOS 26.0, *) {
                RecipeModelGenerationOperations.isAvailable
            } else {
                false
            }
        case .text,
             .photo,
             .website:
            true
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .generation:
            "Create Recipe Draft with AI"
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
