import AppIntents
import SwiftUI

/// Tells Siri and Apple Intelligence which recipe a view shows, so a request
/// such as "this recipe" resolves to the same `RecipeEntity` Shortcuts use.
///
/// Ask Siri presentation in menus stays system-owned; this only supplies the
/// identity the system cannot infer from the rendered text.
struct RecipeEntityAnnotationModifier: ViewModifier {
    let recipe: Recipe

    @ViewBuilder
    func body(
        content: Content
    ) -> some View {
        if #available(iOS 18.4, *) {
            content.appEntityIdentifier(
                .init(
                    for: RecipeEntity.self,
                    identifier: RecipeStableIdentifierCodec.stableIdentifier(
                        for: recipe
                    )
                )
            )
        } else {
            content
        }
    }
}

extension View {
    /// Annotates the view with the recipe it presents.
    func cookleRecipeEntityAnnotation(
        _ recipe: Recipe
    ) -> some View {
        modifier(
            RecipeEntityAnnotationModifier(
                recipe: recipe
            )
        )
    }
}
