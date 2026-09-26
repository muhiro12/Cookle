import SwiftUI

/// Owns the recipe form presenter for one modal context of a scene.
///
/// Apply this above any subtree that switches layout by size class, so the
/// presented form and its draft survive the switch.
struct RecipeFormPresentationHostModifier: ViewModifier {
    @State private var presenter = RecipeFormPresenter()

    func body(content: Content) -> some View {
        @Bindable var presenter = presenter

        content
            .environment(presenter)
            .sheet(item: $presenter.form) { form in
                RecipeFormNavigationView(model: form)
            }
    }
}
