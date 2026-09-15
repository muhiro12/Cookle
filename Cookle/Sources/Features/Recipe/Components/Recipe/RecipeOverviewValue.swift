import MHUI
import SwiftUI

struct RecipeOverviewValue: View {
    @Environment(\.mhTheme)
    private var theme

    let title: LocalizedStringKey
    let value: Text

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.inline) {
            Text(title)
                .mhTextStyle(.supporting, colorRole: .secondaryText)
            value
                .mhTextStyle(.bodyStrong)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
