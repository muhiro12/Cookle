import MHUI
import SwiftUI

struct RecipeSecondaryActions: View {
    @Environment(\.mhTheme)
    private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.section) {
            ShareRecipeLinkButton()
                .buttonStyle(.mhQuiet)
                .mhSectionWithFooter("Sharing") {
                    MHSectionFooter(Text("recipe.shareLink.footer"))
                }

            MHActionGroup(layout: .vertical) {
                DuplicateRecipeButton(showsRecipeName: false)
                    .buttonStyle(.mhQuiet)
                DeleteRecipeButton(showsRecipeName: false)
                    .buttonStyle(.mhDestructive)
            }
            .mhSection("Manage Recipe")
        }
    }
}

#if DEBUG
#Preview("Recipe actions") {
    let assembly = DiaryRecipeSelectionPreview.assembly
    if let recipe = try? assembly.modelContainer.mainContext.fetch(.recipes(.all)).first {
        NavigationStack {
            RecipeSecondaryActions()
                .environment(recipe)
                .mhScreen()
                .navigationTitle(recipe.name)
        }
        .cooklePreviewAppAssembly(assembly)
    }
}
#endif
