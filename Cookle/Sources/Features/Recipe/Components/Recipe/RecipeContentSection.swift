import MHUI
import SwiftUI

struct RecipeContentSection<Content: View>: View {
    private let title: LocalizedStringKey
    private let presentation: RecipeSectionPresentation
    private let content: Content

    var body: some View {
        switch presentation {
        case .native:
            Section {
                content
            } header: {
                Text(title)
            }
        case .mhui:
            MHGroupedRows {
                content
            }
            .mhSection(title)
        }
    }

    init(
        _ title: LocalizedStringKey,
        presentation: RecipeSectionPresentation,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.presentation = presentation
        self.content = content()
    }
}
