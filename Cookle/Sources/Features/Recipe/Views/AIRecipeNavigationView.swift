import SwiftUI

struct AIRecipeNavigationView: View {
    @Environment(RecipeFormPresenter.self)
    private var presenter

    @State private var model = RecipeFormModel(type: .create)

    var body: some View {
        NavigationStack {
            if #available(iOS 26.0, *) {
                InferRecipeFormView(
                    model: model,
                    source: .generation,
                    onInferenceApplied: presentDraft
                )
            } else {
                ContentUnavailableView {
                    Label("Create with AI", systemImage: "sparkles")
                } description: {
                    Text("Apple Intelligence is not available right now.")
                }
            }
        }
    }
}

private extension AIRecipeNavigationView {
    func presentDraft() {
        presenter.present(draft: model)
        model = .init(type: .create)
    }
}
