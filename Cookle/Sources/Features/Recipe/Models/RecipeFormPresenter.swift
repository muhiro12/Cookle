import Observation

/// Presents recipe forms on behalf of views that may be rebuilt while a form is open.
///
/// A size-class change can tear down and rebuild the subtree that holds an
/// edit, duplicate, or add button. A presenter owned by a stable ancestor in
/// the same scene keeps both the presentation and the form's draft alive
/// across that rebuild, while each window keeps its own forms.
@MainActor
@Observable
final class RecipeFormPresenter {
    /// The form currently presented by this presenter's host.
    var form: RecipeFormModel?

    /// Opens a fresh recipe form unless this host already shows one.
    ///
    /// An open form is never replaced, so a repeated request cannot discard
    /// the draft the user is working on.
    func present(
        _ type: RecipeFormType,
        recipe: Recipe? = nil,
        importSource: RecipeImportSource? = nil
    ) {
        guard form == nil else {
            return
        }

        form = .init(
            type: type,
            recipe: recipe,
            importSource: importSource
        )
    }
}
