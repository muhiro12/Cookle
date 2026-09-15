import MHUI
import SwiftUI

struct RecipeSecondaryActions: View {
    @Environment(\.mhTheme)
    private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.content) {
            MHActionGroup {
                ShareRecipeLinkButton()
                    .buttonStyle(.mhQuiet)
                DuplicateRecipeButton()
                    .buttonStyle(.mhQuiet)
            }

            MHSectionFooter(Text("recipe.shareLink.footer"))

            DeleteRecipeButton()
                .buttonStyle(.mhDestructive)
        }
    }
}
