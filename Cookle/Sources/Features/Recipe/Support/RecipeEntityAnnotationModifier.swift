import AppIntents
import SwiftData
import SwiftUI

/// Tells Siri and Apple Intelligence which recipe a view shows, so a request
/// such as "this recipe" resolves to the same `RecipeEntity` Shortcuts use.
///
/// Ask Siri presentation in menus stays system-owned; this only supplies the
/// identity the system cannot infer from the rendered text.
struct RecipeEntityAnnotationModifier: ViewModifier {
    let recipe: Recipe?

    var entityIdentifier: EntityIdentifier? {
        guard let recipe, !recipe.isDeleted, recipe.modelContext != nil else {
            return nil
        }
        return .init(
            for: RecipeEntity.self,
            identifier: RecipeStableIdentifierCodec.stableIdentifier(for: recipe)
        )
    }

    @ViewBuilder
    func body(
        content: Content
    ) -> some View {
        if #available(iOS 18.4, *) {
            content.appEntityIdentifier(entityIdentifier)
        } else {
            content
        }
    }
}

extension View {
    /// Annotates the recipe this view presents, clearing a missing or deleted target.
    func cookleRecipeEntityAnnotation(
        _ recipe: Recipe?
    ) -> some View {
        modifier(
            RecipeEntityAnnotationModifier(
                recipe: recipe
            )
        )
    }
}
