import MHUI
import SwiftUI

struct RecipeContentSection<Content: View>: View {
    @Environment(\.mhTheme)
    private var theme

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
        case .reading:
            VStack(alignment: .leading, spacing: theme.spacing.content) {
                MHSectionHeader(title: Text(title))
                VStack(alignment: .leading, spacing: theme.spacing.content) {
                    content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
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
