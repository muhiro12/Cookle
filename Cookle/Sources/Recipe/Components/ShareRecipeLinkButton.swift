import SwiftData
import SwiftUI

struct ShareRecipeLinkButton: View {
    @Environment(Recipe.self)
    private var recipe

    var body: some View {
        ShareLink(
            item: shareURL,
            subject: Text(recipe.name),
            message: Text("Use this link to reopen \(recipe.name) in Cookle later.")
        ) {
            Label {
                Text("Share Recipe Link")
            } icon: {
                Image(systemName: "link")
                    .accessibilityHidden(true)
            }
        }
    }
}

private extension ShareRecipeLinkButton {
    var shareURL: URL {
        CookleDeepLinkURLBuilder.preferredRecipeDetailURL(
            for: RecipeStableIdentifierCodec.stableIdentifier(
                for: recipe
            )
        )
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    ShareRecipeLinkButton()
        .environment(recipes[0])
}
