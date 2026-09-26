import SwiftUI

extension View {
    /// Hosts recipe forms opened from this view's descendants.
    func recipeFormPresentationHost() -> some View {
        modifier(
            RecipeFormPresentationHostModifier()
        )
    }
}
